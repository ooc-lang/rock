
import AstBuilder2

import rock/middle/ast2/[Module, Import]
import rock/middle/ast2/tinker/Resolver

import threading/Thread, structs/[List, ArrayList], os/[Time, System]

main: func (argc: Int, argv: CString*) {

    if(argc <= 1) {
        "Usage: ast2-rock FILE" println()
        exit(1)
    }
    
    "Parsing %s" printfln(argv[1])
    pool := ParsingPool new()
    mainJob := ParsingJob new(argv[1] toString(), null)
    pool push(mainJob)
    pool exhaust()
    "Done parsing!" println()
    "=================================" println()

    r := Resolver new()
    r modules addAll(mainJob module getDeps())
    r start()
    
}

ParsingJob: class {

    path: String
    module: Module
    _import: Import

    init: func (=path, =_import) {}

}

ParsingPool: class {

    todo := ArrayList<ParsingJob> new()
    done := ArrayList<ParsingJob> new()
    workers := ArrayList<ParserWorker> new()

    active := true

    doneMutex, todoMutex: Mutex

    init: func {
        doneMutex = Mutex new()
        todoMutex = Mutex new()        
    }

    push: func (j: ParsingJob) {
        todoMutex lock()
        todo add(j)
        todoMutex unlock()
    }

    done: func (j: ParsingJob) {
        doneMutex lock()
        done add(j)
        doneMutex unlock()
    }

    pop: func -> ParsingJob {
        job: ParsingJob = null
        todoMutex lock()
        if(todo size > 0) {
            job = todo removeAt(0)
        } else {
            stillActive := false
            workers each(|worker|
                if(worker busy) {
                    // still might have a chance of getting an import
                    stillActive = true
                }
            )
            active = stillActive
        }
        todoMutex unlock()
        job
    }

    exhaust: func {
        active = true
        numCores := numProcessors()
        for(i in 0..(numCores + 1)) {
            worker := ParserWorker new(this). run()
            workers add(worker)
        }

        while (active) {
            Time sleepMilli(10)
        }
    }

}

ParserWorker: class {

    idSeed : static Int = 0
    id: Int
    busy := false
    pool: ParsingPool

    init: func (=pool) {
        idSeed += 1
        id = idSeed
    }

    run: func {
        Thread new(||
            "[%d] Initialized" printfln(id)

            while (pool active) {
                job := pool pop()
                if(job) {
                    busy = true
                    "[%d] Parsing %s" printfln(id, job path toCString())
                    builder := AstBuilder new(pool)
                    builder parse(job path)
                    job module = builder module
                    if(job _import) job _import module = builder module
                    pool done(job)
                    busy = false
                } else {
                    Time sleepMilli(10)
                }
            }

            "Ending worker thread %d" printfln(id)
        ) start()
    }
    
}

