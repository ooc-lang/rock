
import os/Coro, structs/[ArrayList, List]

import ../[Node, Module]

Task: class {
    id: Int { get set }
    idSeed := static 0
    
    parentCoro, coro: Coro
    
    node: Node { get set }
    done?: Bool { get set }

    init: func (=parentCoro, =node) {
        idSeed += 1
        id = idSeed
        coro = Coro new()
        done? = false
        
        (toString() + " created") println()
    }

    start: func {
        (toString() + " started") println()
        parentCoro startCoro(coro, ||
            node resolve(this)
            Exception new("Error! task returned - this shouldn't happened") throw()
        )
    }

    done: func {
        (toString() + " done") println()
        done? = true
        yield()
    }

    yield: func {
        (toString() + " yielding, switching back to parent") println()
        coro switchTo(parentCoro)
    }

    queueAll: func (f: Func (Func (Node))) {
        pool := ArrayList<Node> new()
        f(|n| spawn(n, pool))
        exhaust(pool)
    }

    spawn: func (n: Node, pool: List<Task>) {
        (toString() + " spawning for " + n toString())
        task := Task new(coro, n)
        task start()
        if(!task done?) pool add(task)
    }

    exhaust: func (pool: List<Task>) {
        (toString() + " exhausting pool ") println()
        while(!pool empty?()) {
            oldPool := pool
            pool = ArrayList<Task> new()

            oldPool each(|task|
                (toString() + " switching to unfinished task") println()
                parentCoro switchTo(task coro)
                if(!task done?) pool add(task)
            )

            yield()
        }
    }

    toString: func -> String {
        "[#%d %s]" format(id, node toString() toCString())
    }
}

Resolver: class {

    modules: ArrayList<Module> { get set }

    init: func {
        modules = ArrayList<Module> new()
    }

    resolve: func {
        "Resolver started, with %d module(s)!" printfln(modules size)

        mainCoro := Coro new()
        mainCoro initializeMainCoro()
        
        pool := ArrayList<Task> new()
        modules each(|module|
            task := Task new(mainCoro, module)
            task start()
            if(!task done?) pool add(task)
        )

        "All tasks added, resuming some as needed" println()
        while(!pool empty?()) {
            oldPool := pool
            pool = ArrayList<Task> new()

            oldPool each(|task|
                "Unfinished task, switching to it" println()
                mainCoro switchTo(task coro)
                if(!task done?) pool add(task)
            )
        }

        "All done resolving!" println()
        "=================================" println()
    }

}

