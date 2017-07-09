actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        let alice = Receiver.create(env,"alice")
        let bob = Sender.create(env,"bob")
        bob.lambda_notify(alice)
        /* function call does not work 
        */

class Sender 
    let env: Env
    var name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    /*  this function yields the error:
        "this parameter must be sendable (iso, val or tag)
        let myself:Sender ref = this"   

    */
    fun ref lambda_notify(target: Receiver ref)=>
        let myself:Sender ref = this
            target.lambda_call({(target: Receiver ref)(myself)=>
            target.lambda_notify()
            myself.finished_box(target.name)
            /* this method call is not working
            myself.finished_ref(target.name)  
            */
            } ref)
    fun box finished_box(from: String val)=>
        env.out.print(name+": successfully passed notification to "+from)

    /* this function gives an error 
    fun ref finished_ref(from: String val)=>
        name = name+"_done_with_"+from
        env.out.print(name+": successfully passed notification to "+from)

                Error:
                receiver type is not a subtype of target type
                        myself.finished_ref(target.name)
                                           ^
                Info:
                receiver type: this->Sender ref
                            myself.finished_ref(target.name)
                            ^
                target type: Sender ref
                    fun ref finished_ref(from: String val)=>
                    ^
                Sender box is not a subtype of Sender ref: box is not a subcap of ref
                        let myself:Sender ref = this
   
    */

class Receiver 
    let env: Env
    let name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    fun ref lambda_call(fn:{(Receiver ref)} ref) =>
        fn(this)
    fun ref lambda_notify() =>
        env.out.print(name+": notified")
