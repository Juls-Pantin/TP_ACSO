/**
 * File: thread-pool.cc
 * --------------------
 * Presents the implementation of the ThreadPool class.
 */

#include "thread-pool.h"
using namespace std;

ThreadPool::ThreadPool(size_t numThreads) : wts(numThreads), done(false) {
    for (size_t i = 0; i < numThreads; ++i) {
        wts[i].available = true;
        wts[i].ts = thread([this, i] { worker(i); });
    }

    dt = thread([this] { dispatcher(); });
}


void ThreadPool::schedule(const function<void(void)>& thunk) {
    {
        unique_lock<mutex> lock(queueLock);
        taskQueue.push(thunk);
    }

    {
        unique_lock<mutex> lock(pendingMtx);
        pendingTasks++;
    }

    taskCv.notify_one();  // avisamos al dispatcher que hay trabajo nuevo
}

void ThreadPool::dispatcher() {
    while (true) {
        function<void(void)> task;

        {
            unique_lock<mutex> lock(queueLock);
            taskCv.wait(lock, [this] {
                return !taskQueue.empty() || done;
            });

            if (done && taskQueue.empty()) return;

            task = taskQueue.front();
            taskQueue.pop();
        }

        int workerId = -1;
        while (true) {
            for (size_t i = 0; i < wts.size(); ++i) {
                unique_lock<mutex> lock(wts[i].mtx);
                if (wts[i].available) {
                    wts[i].available = false;
                    wts[i].thunk = task;
                    workerId = i;
                    break;
                }
            }
            if (workerId != -1) break;
            this_thread::yield();
        }

        wts[workerId].sem.signal();
    }
}

void ThreadPool::worker(int id) {
    while (true) {
        wts[id].sem.wait();  // espera a que el dispatcher lo despierte

        if (done) return;    // salir si se está destruyendo el thread pool

        // Ejecuta el thunk asignado
        wts[id].thunk();

        {
            unique_lock<mutex> lock(wts[id].mtx);
            wts[id].available = true;
        }

        // Actualizar la cantidad de tareas pendientes
        bool notify = false;
        {
            unique_lock<mutex> lock(pendingMtx);
            pendingTasks--;
            notify = (pendingTasks == 0);
        }

        if (notify) {
            pendingCv.notify_all();  // despierta al wait() si no quedan tareas
        }
    }
}

void ThreadPool::wait() {
    unique_lock<mutex> lock(pendingMtx);
    pendingCv.wait(lock, [this] {
        return pendingTasks == 0;
    });
}

ThreadPool::~ThreadPool() {
    // Asegurarse de que se ejecutaron todas las tareas
    wait();

    // Marcar que estamos destruyendo el pool
    done = true;

    // Despertar al dispatcher
    taskCv.notify_all();

    // Despertar a todos los workers
    for (auto& worker : wts) {
        worker.sem.signal();
    }

    // Esperar a que todos los threads terminen
    if (dt.joinable()) {
        dt.join();
    }

    for (auto& worker : wts) {
        if (worker.ts.joinable()) {
            worker.ts.join();
        }
    }
}