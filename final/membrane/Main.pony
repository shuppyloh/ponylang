use collections = "collections"
actor Main
    let env: Env
    new create(env':Env)=>
        env = env'
        env.out.print("test")
        let alice: Node ref = Node.create(env,"alice")
        let bob: Node ref = Node.create(env,"bob")
        let carol: Node ref = Node.create(env,"carol")
        let diane: Node ref = Node.create(env,"diane")
        try
        carol.recCap("diane",diane)
        diane.sendProp("diane_prop1","true","diane")
        alice.recCap("bob",bob)
        alice.recCap("carol",carol)
        alice.createMemb("carol-Memb","carol") //carol-CT caretaker created
        alice.sendCap("carol-Memb","bob") //alice sends carol-CT to bob
        bob.sendProp("carol_prop1","true","carol-Memb") //bob sends property (prop1 = true) to carol-CT
        bob.sendCap("bob","carol-Memb")
        carol.sendCap("diane","bob")
        env.out.print("carol_prop1 is "+carol.getProp("carol_prop1")) //this carol's prop1 should return true
        alice.changelock(true,"carol-Memb") //alice locks carol-CT
        bob.sendProp("carol_prop1","false","carol-Memb") //bob tries to change prop1 = false to carol-CT
        bob.sendProp("diane_prop1","false","diane") //bob tries to change prop1 = false to carol-CT
        env.out.print("carol_prop1 is "+carol.getProp("carol_prop1")) //this carol's prop1 should return true
        env.out.print("diane_prop1 is "+diane.getProp("diane_prop1")) //because caretaker is locked, should return true

        end


class Membrane 
    let env: Env
    var _locked: Bool val
    let _owner: (Node ref|Membrane ref)
    let _target: (Node ref|Membrane ref)
    let _children: collections.Map[String val, Membrane ref] = _children.create()
    new ref create(env': Env, owner':(Node ref|Membrane ref), target':(Node ref|Membrane ref))=>
        env = env'; _owner = owner'; _target = target'
        _locked = false
    fun ref unlock(owner':(Node ref|Membrane ref))=>
        if _owner is owner' then 
        for each_cap in _children.values() do each_cap.unlock(this) end
        _locked = false end
    fun ref lock(owner':(Node ref|Membrane ref))=>
        if _owner is owner' then 
        for each_cap in _children.values() do each_cap.lock(this) end
        _locked = true end
    fun box getProp(id:String val):String val?=>
        try
            if _locked is false then _target.getProp(id) else error end
        else error end
    fun ref sendProp(id:String val,prop:String val,rec: String val)?=>
        try
            if _locked is false then _target.sendProp(id,prop,rec) else error end
        else error end
    fun ref recProp(id:String val,prop:String val)=>
        if _locked is false then _target.recProp(id,prop) end
    fun ref getCap(id:String val): (Node ref|Membrane ref)?=>
        try
            if _locked is false then _target.getCap(id) else error end
        else error end
    fun ref sendCap(id:String val, rec:String val)?=>
        try
            if _locked is false then _target.sendCap(id,rec) end
        else error end
    fun ref recCap(id:String val, cap':(Node ref|Membrane ref))=> //wrap capability parameter in method
        if _locked is false then 
        let newMemb = Membrane.create(env,this,cap')
        _children(id) = newMemb
        _target.recCap(id,newMemb) end
    fun ref delCap(id:String val)?=>
        try
            if _locked is false then _target.delCap(id) end
        else error end
    fun ref createMemb(id:String val,target:String val):Membrane ref?=>
        try
            if _locked is false then _target.createMemb(id,target) else error end
        else error end
            
class Node
    let env: Env
    let name: String
    let _caps: collections.Map[String val, (Node ref|Membrane ref)] = _caps.create()
    let _props: collections.Map[String val, String val] = _props.create()

    new ref create(env':Env, name':String)=>
        env = env'; name = name'
        _caps(name) = this
    fun ref changelock(lock:Bool val,rec: String val)?=>
        try if lock is true then (getCap(rec) as Membrane).lock(this) 
        else (getCap(rec) as Membrane).unlock(this) end
        env.out.print(name+": changing lock of "+rec+" to "+lock.string())
        else error end
    fun box getProp(id:String val):String val ?=>
        try _props(id) else error end
    fun ref sendProp(id:String val,prop:String val,rec: String val)?=>
        try getCap(rec).recProp(id,prop) else error end
    fun ref recProp(id:String val,prop:String val) =>
        env.out.print(name+":"+id+" changed to "+prop)
        _props(id)=prop
    fun ref getCap(id:String val): (Node ref|Membrane ref)?=>
        try _caps(id) else error end
    fun ref sendCap(id:String val, rec:String val)?=>
        try getCap(rec).recCap(id, getCap(id)) else error end
    fun ref recCap(id:String val, cap':(Node ref|Membrane ref))=>
        _caps(id) = cap'
        env.out.print(name+":received capability of "+id)
    fun ref delCap(id:String val) ?=>
        try _caps.remove(id) else error end
    fun ref createMemb(id:String val,target':String val):Membrane ref?=>
        try
            let cap: Node ref = (getCap(target') as Node ref)
            let membrane:Membrane ref = Membrane.create(env,this,cap) 
            recCap(id, membrane)
            membrane
        else error end
