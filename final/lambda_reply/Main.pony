actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        let alice = Receiver.create(env,"alice")
        let bob = Sender.create(env,"bob")
        /* function call does not work 
        bob.lambda_notify(alice)
        */
        bob.direct_notify(alice) //this works

class Sender 
    let env: Env
    let name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    /*  this function yields the error:
        "this parameter must be sendable (iso, val or tag)
        let myself:Sender ref = this"   

    fun ref lambda_notify(target: Receiver ref)=>
        let myself:Sender ref = this
            target.lambda_call({(target: Receiver ref)(myself)=>
            target.lambda_notify()
            myself.finished(target.name)
            }val)
    */
    fun ref direct_notify(target: Receiver ref)=>
        target.direct_notify(this)
    fun ref finished(from: String val)=>
        env.out.print(name+": successfully passed notification to "+from)

class Receiver 
    let env: Env
    let name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    fun ref lambda_call(fn:{(Receiver ref)}val) =>
        fn(this)
    fun ref lambda_notify() =>
        env.out.print(name+": notified")
    fun ref direct_notify(sender: Sender ref) =>
        env.out.print(name+": notified")
        sender.finished(name)
