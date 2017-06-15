"""
PROGRAM OUTPUT:
Alice says I found a seller Carol for buyer Bob
Alice creating caretaker for Carol and passing it to Bob...
Bob says I received exchange authorisation to buy from Carol
Bob says I tell Carol I want to buy
...(CARETAKER) forwarding message to Carol
Carol says I received Bob's request to buy
Carol says Sold!
...After 3 seconds...
...(CARETAKER) Permission to access Carol disabled by owner (Alice)
...After 3 seconds...
Bob executing malicious buy...I will enable permission in caretaker and call sellto method on Carol
...(CARETAKER) Unauthorised access to change permission. DENIED
...(CARETAKER) Permission to access Carol denied
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
        alice.give_access_to(carol)

        alice.start()
        this.wait1()

    be wait1()=>
        let timer = Timer(TimeDisable(this), 3_000_000_000)
        timers(consume timer)
        
    be exec_alice_disable()=>
        _env.out.print("...After 3 seconds...Alice disables access to Carol")
        alice.disable()
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
    let _target: Agent
    let _targetname: String
    let _owner: Any tag 
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
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" enabled")
		else 	
        	_env.out.print("...(CARETAKER) Unauthorised access to change permission. DENIED")
        end

    be disable(owner: Any tag)=>
        if owner is _owner then
            permission = false 
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" disabled")
		else	
        	_env.out.print("...(CARETAKER) Unauthorised access to change permission. DENIED")
		end

    be sellto(buyername:String)=>
        if permission is true then 
            this.printmsg()
            _target.sellto(buyername)
		else
        	_env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
        end
   
    be grant_access_to(agent:(Agent|Caretaker))=>
        if permission is true then 
            this.printmsg()
            _target.grant_access_to(agent)
		else
        	_env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
        end
    be get_access(exchange:Exchange)=>
        if permission is true then 
            this.printmsg()
            _target.get_access(exchange)
		else
        	_env.out.print("...(CARETAKER) Permission to access " + _targetname + " denied")
        end
    fun printmsg()=>
        _env.out.print("...(CARETAKER) forwarding message to " + _targetname)
        

actor Agent
    let _name: String
    let _env: Env 
    var _counterparty: Caretaker 
    var _exchange: Exchange 
    new create(env: Env, name:String)=>
        _env = env
        _name = name
        _counterparty = Caretaker.create(env, this, this, name)//default counterparty is caretaker of himself
        _exchange = Exchange.create(env,_name,this,_name,this,_name) //default no access to exchange but of himself
    be authorise(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says I received exchange authorisation to buy from " + sellername)
        _env.out.print(_name+" says I tell " + sellername+ " I want to buy")
        _env.out.print(_name+" says I gain malicious access to Alice through Carol")
        _counterparty = seller //Change counterparty to given Caretaker
        this.malicious_access()
        _counterparty.sellto(_name) 
    be sellto(buyername: String) =>
        _env.out.print(_name+" says I received " + buyername+ "'s request to buy")
        _env.out.print(_name+" says Sold!")
    be malicious_access()=>
        _counterparty.grant_access_to(this)
    be malicious_enable()=>        
        _env.out.print(_name+" executing malicious buy...I will enable permission of caretaker through Alice")
		_exchange.enable() 
    be malicious_buy()=>        
        _env.out.print(_name+" executing unauthorised transaction...calling sellto method on Carol")
        _counterparty.sellto(_name) //this will fail if the owner disabled access
    be grant_access_to(agent:(Agent|Caretaker)) =>
        _exchange.give_access_to(agent)
    be get_access(exchange: Exchange) =>
        _exchange=exchange
   
   

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
        caretaker = Caretaker.create(_env, this, _a2, _a2name)

    be start()=>
        _env.out.print(_name+" says I found a seller Carol for buyer Bob")
        _env.out.print(_name+" creating caretaker for Carol and passing it to Bob...")
        _a1.authorise(caretaker,_a2name)

    be disable()=>
        caretaker.disable(this)

    be enable()=>
        caretaker.enable(this)

    be give_access_to(agent:(Agent|Caretaker)) =>
        agent.get_access(this)
