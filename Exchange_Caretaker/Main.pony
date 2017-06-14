"""
Alice says I found a seller Carol for buyer Bob
Alice creating caretaker for Carol and passing it to Bob...
Bob says I received exchange authorisation to buy from Carol
Bob says I tell Carol I want to buy
...(CARETAKER) forwarding message to Carol
Carol says I received Bob's request to buy
Carol says Sold!
Carol says transaction complete, closing caretaker to myself, sending Bob confirmation
...(CARETAKER) forwarding message to Bob
Bob says transaction complete, closing caretaker to myself
"""
actor Main
    new create(env: Env)=>
        let bob = Agent.create(env,"Bob")
        let carol = Agent.create(env,"Carol")
        let alice = Exchange.create(env,"Alice",bob,"Bob",carol,"Carol")
        alice.start()

actor Caretaker
    let _env: Env
    let _target: Agent
    let _targetname: String
    let _owner: Any
    var permission: Bool
    new create(env: Env, owner:Any tag, target:Agent, targetname:String)=>
        _env = env
        _owner = owner
        _target = target
        _targetname = targetname
        permission = true 
    be enable(owner: Any tag)=>
        if owner is _owner then
            permission = true
        end
    be disable(owner: Any tag)=>
        if owner is _owner then
            permission = false 
        end
    be buyfrom(seller: Caretaker, sellername:String)=>
        if permission is true then 
            this.printmsg()
            _target.buyfrom(seller, sellername)
        end
    be sellto(buyer: Caretaker, buyername: String) =>
        if permission is true then 
            this.printmsg()
            _target.sellto(buyer, buyername)
        end
    be buy_success(seller: Caretaker, sellername:String)=>
        if permission is true then 
            this.printmsg()
            _target.buy_success(seller, sellername)
        end
    fun printmsg()=>
        _env.out.print("...(CARETAKER) forwarding message to " + _targetname)
        

actor Agent
    let _name: String
    let _env: Env 
    let caretaker_this: Caretaker 
    new create(env: Env, name:String)=>
        _env = env
        _name = name
        caretaker_this = Caretaker.create(_env, this, this,_name)
    be authorise(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says I received exchange authorisation to buy from " + sellername)
        this.buyfrom(seller,sellername)
    be buyfrom(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says I tell " + sellername+ " I want to buy")
        seller.sellto(caretaker_this, _name) 
    be sellto(buyer: Caretaker, buyername: String) =>
        _env.out.print(_name+" says I received " + buyername+ "'s request to buy")
        _env.out.print(_name+" says Sold!")
        this.sell_success(buyer)
    be sell_success(buyer: Caretaker) =>    
        buyer.buy_success(caretaker_this, _name)
        _env.out.print(_name+" says transaction complete, closing caretaker to myself, sending Bob confirmation")
        caretaker_this.disable(this)
    be buy_success(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says transaction complete, closing caretaker to myself")
        caretaker_this.disable(this)
        
        
actor Exchange 
    let _name: String
    let _env: Env
    let bob: Agent
    let bobname: String
    let carol: Agent
    let carolname: String

    new create(env:Env, name:String, a1: Agent, a1name: String, a2: Agent, a2name: String)=>
        _env = env
        _name = name
        bob = a1 
        bobname = a1name
        carol = a2
        carolname = a2name
    be start()=>
        _env.out.print(_name+" says I found a seller Carol for buyer Bob")
        _env.out.print(_name+" creating caretaker for Carol and passing it to Bob...")
        let caretaker_carol: Caretaker = Caretaker.create(_env, this, carol,carolname)
        bob.authorise(caretaker_carol,carolname)
        //after awhile, the exchange should disable the caretaker (caretaker_carol.disable(this))
