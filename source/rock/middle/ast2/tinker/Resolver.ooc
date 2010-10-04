
import os/Coro, structs/ArrayList

import ../[Node, Module]

Task: class {
    parentCoro, coro: Coro
    
    node: Node { get set }
    done?: Bool { get set }

    init: func (=parentCoro, =node) {
        ("Initialized new task for node [" + node class name + "]") println()
        coro = Coro new()
        done? = false
    }

    start: func {
        parentCoro startCoro(coro, ||
            node resolve(this)
            Exception new("Error! task returned - this shouldn't happened") throw()
        )
    }

    done: func {
        "Task done, switching back to main coro" println()
        done? = true
        coro switchTo(parentCoro)
    }

    yield: func {
        "Task yielding, switching back to main" println()
        coro switchTo(parentCoro)
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

        "All tasks added, resuming some as needed"
        while(!pool empty?()) {
            oldPool := pool
            pool = ArrayList<Task> new()

            oldPool each(|task|
                "Unfinished task, switching to it"
                mainCoro switchTo(task coro)
                if(!task done?) pool add(task)
            )
        }

        "All done resolving!" println()
        "=================================" println()
    }

}

