"""
PROGRAM OUTPUT:
...(MAIN) Alice trusts Carol, and gives Carol her capability
Alice says I found a seller Carol for buyer Bob
Alice creating caretaker for Carol and passing it to Bob...
Bob says I received exchange authorisation to buy from Carol
Bob says I tell Carol I want to buy
Bob says I gain malicious access to Alice through Carol
...(CARETAKER) forwarding message to Carol
...(CARETAKER) forwarding message to Carol
Carol says I received Bob's request to buy
Carol says Sold!
...After 3 seconds...Alice disables access to Carol
...(CARETAKER) Permission to access Carol disabled
...After 3 seconds...Bob commences malicious activity
Bob executing malicious buy...I will enable permission of caretaker through Alice
...(CARETAKER) Permission to access Carol enabled
Bob executing unauthorised transaction...calling sellto method on Carol
...(CARETAKER) forwarding message to Carol
Carol says I received Bob's request to buy
Carol says Sold!
"""
use "time"

actor Main
    let _env: Env
    let bob: Agent
    let carol: Agent
    let alice: Exchange
    let timers: Timers

    new create(env: Env)=>
        _env = env
        timers = Timers
        bob = Agent.create(env,"Bob")
        carol = Agent.create(env,"Carol")
        alice = Exchange.create(env,"Alice",bob,"Bob",carol,"Carol")
        _env.out.print("...(MAIN) Alice trusts Carol, and gives Carol her capability ")
        alice.give_capability_to(carol)

        alice.start()
        this.wait1()

    be wait1()=>
        let timer = Timer(TimeDisable(this), 3_000_000_000)
        timers(consume timer)
        
    be exec_alice_disable()=>
        _env.out.print("...After 3 seconds...Alice disables access to Carol")
        alice.disableCaretaker()
        this.wait2()

    be wait2()=>
        let timer = Timer(TimeMaliciousEnable(this), 3_000_000_000)
        timers(consume timer)

    be exec_bob_malicious_enable()=>
        _env.out.print("...After 3 seconds...Bob commences malicious activity")
        bob.malicious_enable()
        this.wait3()

    be wait3()=>
        let timer = Timer(TimeMaliciousBuy(this), 3_000_000_000)
        timers(consume timer)

    be exec_bob_malicious_buy()=>
        bob.malicious_buy()


class TimeDisable is TimerNotify
let _holder: Main
    new iso create(holder: Main) =>
        _holder = holder
    fun ref apply(timer: Timer, count: U64): Bool =>
        _holder.exec_alice_disable()
false


class TimeMaliciousEnable is TimerNotify
let _holder: Main
    new iso create(holder: Main) =>
        _holder = holder
    fun ref apply(timer: Timer, count: U64): Bool =>
        _holder.exec_bob_malicious_enable()
false

class TimeMaliciousBuy is TimerNotify
let _holder: Main
    new iso create(holder: Main) =>
        _holder = holder
    fun ref apply(timer: Timer, count: U64): Bool =>
        _holder.exec_bob_malicious_buy()
false


actor Caretaker
    let _env: Env
    let _target: (Agent|Caretaker|Exchange)
    let _targetname: String
    let _owner: Any tag 
    var _permission: Bool 
    let children: Array[Caretaker tag] = Array[Caretaker]

    new create(env: Env, owner:Any tag, permission:Bool , target:(Agent|Caretaker|Exchange), targetname:String)=>
        _env = env
        _owner = owner
        _permission = permission
        _target = target
        _targetname = targetname

    be enable(owner: Any tag)=>
        if owner is _owner then
            _permission = true 
            for child in children.values() do
                child.enable(this)
            end   
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" enabled")
		else 	
        	_env.out.print("...(CARETAKER) Unauthorised access to change permission. DENIED")
        end

    be disable(owner: Any tag)=>
        if owner is _owner then
            _permission = false
            for child in children.values() do
                child.disable(this)
            end   
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" disabled")
        else	
        	_env.out.print("...(CARETAKER) Unauthorised access to change permission. DENIED")
		end

    be sellto(buyername:String)=>
        try
            if _permission is true then 
                this.printmsg()
                (_target as (Agent|Caretaker)).sellto(buyername)
            else
                _env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
            end
        end

    be enableCaretaker() =>
        try
            if _permission is true then 
                this.printmsg()
                (_target as (Exchange|Caretaker)).enableCaretaker()
            else
                _env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
            end
        end    
   
    be give_exchangeCapability(agent:(Agent|Caretaker))=>
        try
            if _permission is true then 
                this.printmsg()
                let caretaker_child=Caretaker.create(_env, this, _permission, agent,"caretaker_child") 
                children.push(caretaker_child)
                (_target as (Agent|Caretaker)).give_exchangeCapability(caretaker_child)
            else
                _env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
            end
        end   

    be give_capability_to(agent:(Agent|Caretaker)) =>
        try
            if _permission is true then 
                this.printmsg()
                let caretaker_child=Caretaker.create(_env, this, _permission, agent,"caretaker_child") 
                children.push(caretaker_child)
                (_target as (Exchange|Caretaker)).give_capability_to(caretaker_child)
            else
                _env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
            end
        end

    be get_exchangeCapability_from(exchange:(Exchange|Caretaker))=>
        try
            if _permission is true then 
                this.printmsg()
                let caretaker_child=Caretaker.create(_env, this, _permission, exchange,"caretaker_child") 
                children.push(caretaker_child)
                (_target as (Agent|Caretaker)).get_exchangeCapability_from(caretaker_child)
            else
                _env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
            end
        end

    fun printmsg()=>
        _env.out.print("...(CARETAKER) forwarding message to " + _targetname)
        

actor Agent
    let _name: String
    let _env: Env 
    var _counterparty: Caretaker 
    var _exchange: (Exchange|Caretaker) 
    new create(env: Env, name:String)=>
        _env = env
        _name = name
        _counterparty = Caretaker.create(env, this, true,  this, name)//placeholder counterparty (agent itself)
        _exchange = Exchange.create(env,_name,this,_name,this,_name) //placeholder exchange (agent itself)
    be authorise(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says I received exchange authorisation to buy from " + sellername)
        _env.out.print(_name+" says I tell " + sellername+ " I want to buy")
        _env.out.print(_name+" says I gain malicious access to Alice through Carol")
        _counterparty = seller //Change counterparty to authorised Caretaker
        this.malicious_access()
        _counterparty.sellto(_name) 
    be sellto(buyername: String) =>
        _env.out.print(_name+" says I received " + buyername+ "'s request to buy")
        _env.out.print(_name+" says Sold!")
    be malicious_access()=>
        _counterparty.give_exchangeCapability(this)
    be malicious_enable()=>        
        _env.out.print(_name+" executing malicious buy...I will enable permission of caretaker through Alice")
		_exchange.enableCaretaker() 
    be malicious_buy()=>        
        _env.out.print(_name+" executing unauthorised transaction...calling sellto method on Carol")
        _counterparty.sellto(_name) 
    be give_exchangeCapability(agent:(Agent|Caretaker)) =>
        agent.get_exchangeCapability_from(_exchange)
    be get_exchangeCapability_from(exchange: (Exchange|Caretaker)) =>
        _exchange=exchange //Change exchange to the Exchange granting capability
   
   

actor Exchange 
    let _name: String
    let _env: Env
    let _a1: Agent
    let _a1name: String
    let _a2: Agent
    let _a2name: String
    var caretaker: Caretaker

    new create(env:Env, name:String, a1: Agent, a1name: String, a2: Agent, a2name: String)=>
        _env = env;_name = name; _a1 = a1; _a1name = a1name; _a2 = a2; _a2name = a2name
        caretaker = Caretaker.create(_env, this, true, _a2, _a2name)

    be start()=>
        _env.out.print(_name+" says I found a seller Carol for buyer Bob")
        _env.out.print(_name+" creating caretaker for Carol and passing it to Bob...")
        _a1.authorise(caretaker,_a2name)

    be disableCaretaker()=>
        caretaker.disable(this)

    be enableCaretaker()=>
        caretaker.enable(this)

    be give_capability_to(agent:(Agent|Caretaker)) =>
        agent.get_exchangeCapability_from(this)
