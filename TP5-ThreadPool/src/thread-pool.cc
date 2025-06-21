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
    if (!thunk){
        throw invalid_argument("Cannot schedule a null task"); // no se puede programar una tarea nula
    }
    if (done) {
        throw runtime_error("Cannot schedule tasks on a destroyed ThreadPool");
    }
    {
        unique_lock<mutex> lock(queueLock);
        taskQueue.push(thunk);
        taskCv.notify_one();  // notifica al dispatcher que hay una nueva tarea
    }

    {
        unique_lock<mutex> lock(pendingMtx);
        pendingTasks++;
    }
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

        // ejecuta el thunk asignado
        wts[id].thunk();

        {
            unique_lock<mutex> lock(wts[id].mtx);
            wts[id].available = true;
        }

        // actualizar la cantidad de tareas pendientes
        bool notify = false;
        {
            unique_lock<mutex> lock(pendingMtx);
            pendingTasks--;
            notify = (pendingTasks == 0);
        }

        if (notify) {
            pendingCv.notify_all();  // "despierta" al wait() si no quedan tareas
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
    // me aseguro que se ejecutaron todas las tareas
    wait();

    // marco que estamos destruyendo el pool
    done = true;

    // "despierto" al dispatcher
    {
        unique_lock<mutex> lock(queueLock);
        taskCv.notify_all();
    }

    // 'despierto" a todos los workers
    for (auto& worker : wts) {
        worker.sem.signal();
    }

    // espero a que todos los threads terminen
    if (dt.joinable()) {
        dt.join();
    }

    for (auto& worker : wts) {
        if (worker.ts.joinable()) {
            worker.ts.join();
        }
    }
}