#ifndef _thread_pool_
#define _thread_pool_

#include <cstddef>     // for size_t
#include <functional>  // for the function template used in the schedule signature
#include <thread>      // for thread
#include <vector>      // for vector
#include "Semaphore.h" // for Semaphore
#include <queue>       // for queue

using namespace std;

typedef struct worker {
    thread ts;
    function<void(void)> thunk;
    Semaphore sem;                          //permite q el worker duerma hasta que el dispatcher le asigne una tarea/haya trabajo
    bool available = true;                  //indica que worker esta disponible para despertar
    mutex mtx;                              //protege el acceso a la variable 'available' y 'thunk'
} worker_t;

class ThreadPool {
  public:

    ThreadPool(size_t numThreads);

    void schedule(const function<void(void)>& thunk);

    void wait();

    ~ThreadPool();
    
  private:

    void worker(int id);
    void dispatcher();

    thread dt;                              // dispatcher thread handle
    vector<worker_t> wts;                   // worker thread handles. you may want to change/remove this
    
    queue<function<void(void)>> taskQueue;  //cola de tareas
    mutex queueLock;                        // mutex to protect the queue of tasks
    condition_variable taskCv;              //notifica al dispatcher

    size_t pendingTasks = 0;                // cantidad de tareas pendientes
    mutex pendingMtx;                       //protege el acceso a pendingTasks
    condition_variable pendingCv;           // notifica al hilo que espera a que todas las tareas se hayan ejecutado

    bool done = false;                      // indica si el ThreadPool está en proceso de destrucción
  
  
    ThreadPool(const ThreadPool& original) = delete;
    ThreadPool& operator=(const ThreadPool& rhs) = delete;
};
#endif
