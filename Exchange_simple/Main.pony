actor Main
    new create(env: Env)=>
        let bob = Agent.create(env,"Bob")
        let carol = Agent.create(env,"Carol")
        let alice = Exchange.create(env,"Alice",bob,carol)
        alice.start()
actor Agent
    let _name: String val
    let _env: Env 
    new create(env: Env, name:String)=>
        _env = env
        _name = name
    be buyfrom(seller: Agent)=>
        seller.sellto(this) 
    be sellto(buyer: Agent) =>
        _env.out.print("sold!")
        
actor Exchange 
    let _name: String
    let _env: Env
    var _contact1: Agent
    var _contact2: Agent
    new create(env:Env, name:String, contact1: Agent, contact2: Agent)=>
        _env = env
        _name = name
        _contact1 = contact1
        _contact2 = contact2
    be start()=>
        _contact1.buyfrom(_contact2)

