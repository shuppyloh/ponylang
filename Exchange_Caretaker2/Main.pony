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

        alice.start()
        this.wait1()

    be wait1()=>
        let timer = Timer(TimeDisable(this), 3_000_000_000)
        timers(consume timer)
        
    be exec_alice_disable()=>
        _env.out.print("...After 3 seconds...")
        alice.disable()
        this.wait2()

    be wait2()=>
        let timer = Timer(TimeMalicious(this), 3_000_000_000)
        timers(consume timer)

    be exec_bob_malicious()=>
        _env.out.print("...After 3 seconds...")
        bob.malicious_buy()


class TimeDisable is TimerNotify
let _holder: Main
    new iso create(holder: Main) =>
        _holder = holder
    fun ref apply(timer: Timer, count: U64): Bool =>
        _holder.exec_alice_disable()
false


class TimeMalicious is TimerNotify
let _holder: Main
    new iso create(holder: Main) =>
        _holder = holder
    fun ref apply(timer: Timer, count: U64): Bool =>
        _holder.exec_bob_malicious()
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
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" enabled by owner (Alice)")
		else 	
        	_env.out.print("...(CARETAKER) Unauthorised access to change permission. DENIED")
        end

    be disable(owner: Any tag)=>
        if owner is _owner then
            permission = false 
        	_env.out.print("...(CARETAKER) Permission to access "+_targetname+" disabled by owner (Alice)")
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
   
	fun printmsg()=>
        _env.out.print("...(CARETAKER) forwarding message to " + _targetname)
        

actor Agent
    let _name: String
    let _env: Env 
    var _counterparty: Caretaker 
    new create(env: Env, name:String)=>
        _env = env
        _name = name
        _counterparty = Caretaker.create(env, this, this, name)//default counterparty is caretaker of himself
    be authorise(seller: Caretaker, sellername:String)=>
        _env.out.print(_name+" says I received exchange authorisation to buy from " + sellername)
        _env.out.print(_name+" says I tell " + sellername+ " I want to buy")
        _counterparty = seller //Change counterparty to given Caretaker
        _counterparty.sellto(_name) 
    be malicious_buy()=>        
        _env.out.print(_name+" executing malicious buy...I will enable permission in caretaker and call sellto method on Carol" )
		_counterparty.enable(this) //this will fail because not owner
        _counterparty.sellto(_name) //this will fail if the owner disabled access
    be sellto(buyername: String) =>
        _env.out.print(_name+" says I received " + buyername+ "'s request to buy")
        _env.out.print(_name+" says Sold!")
   

actor Exchange 
    let _name: String
    let _env: Env
    let bob: Agent
    let bobname: String
    let carol: Agent
    let carolname: String
    var caretaker_carol: Caretaker

    new create(env:Env, name:String, a1: Agent, a1name: String, a2: Agent, a2name: String)=>
        _env = env
        _name = name
        bob = a1 
        bobname = a1name
        carol = a2
        carolname = a2name
        caretaker_carol = Caretaker.create(_env, this, carol,carolname)

    be start()=>
        _env.out.print(_name+" says I found a seller Carol for buyer Bob")
        _env.out.print(_name+" creating caretaker for Carol and passing it to Bob...")
        bob.authorise(caretaker_carol,carolname)

    be disable()=>
        caretaker_carol.disable(this)
