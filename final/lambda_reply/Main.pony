// The purpose of this snippet is to demonstarte how, through the unde of 
// lambda-s, it is possible to instruct an object to notify another object
// without allowing the first object to store the identity of the secvond one

// Can you turn Sender and Receiver to actors?

actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        let bob = Sender.create(env,"bob")
        let alice = Receiver.create(env,"alice")
        bob.lambda_notify(alice)

class Sender 
    let env: Env
    var name: String
    var status: String
    new create(env':Env, name':String)=>
        env = env'; name = name'; status = "Not Done"
    fun ref lambda_notify(target: Receiver ref)=>
        let myself:Sender ref = this
            target.lambda_call({ref (target: Receiver ref) (myself)=>
            target.lambda_notify()
            myself.finished_ref(target.name)  
            } )
    fun ref finished_ref(from: String val)=>
        status = "Done"
        env.out.print(name+": status is "+status+"- successfully passed notification to "+from)

class Receiver 
    let env: Env
    let name: String
    new create(env':Env, name':String)=>
        env = env'; name = name'
    fun ref lambda_call(fn:{ref (Receiver ref)}) =>
        fn(this)
    fun ref lambda_notify() =>
        env.out.print(name+": notified")
