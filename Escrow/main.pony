
use "time"
actor Main
    let sellerMoney:Purse
    let sellerGoods:Purse
    let buyerMoney:Purse
    let buyerGoods:Purse
    let env:Env
    new create(env': Env)=>
        env = env'
        env.out.print("---Constructing purses---")
        sellerMoney = Purse.create(env, "sellerMoney","GBP",0)
        sellerGoods= Purse.create(env, "sellerGoods","Book",1)
        buyerMoney = Purse.create(env, "buyerMoney","GBP",50)
        buyerGoods= Purse.create(env, "buyerGoods","Book",0)
        env.out.print("---Constructor completed---")
        env.out.print("---Dealing---")
        deal(10,"Book",1)
        env.out.print("---Deal completed---")
    fun ref deal(price:U32, good:String, amt: U32):Bool=>
        env.out.print("The Deal is buyer pays "+price.string()+sellerMoney.resource_type+" to buy "+amt.string()+good)
        let escrowMoney:Purse = sellerMoney.sprout()
        let escrowGoods:Purse = buyerGoods.sprout()

        env.out.print("---moneyTransfer to escrowMoney from BuyerMoney---")
        let moneyTransfer: Bool = escrowMoney.deposit(price,buyerMoney)
        if moneyTransfer is false then 
            env.out.print("insufficient money or different mint/currency") 
            return false end
        escrowMoney.printbal()
        buyerMoney.printbal()
        env.out.print("---Done---")

        env.out.print("---goodsTransfer to escrowGoods from sellerGoods---")
        let goodsTransfer: Bool = escrowGoods.deposit(amt,sellerGoods)
        if goodsTransfer is false then  //we have to reverse the buyer transaction
            env.out.print("insufficient amt of good") 
            buyerMoney.deposit(price, escrowMoney)
            return false end
        escrowGoods.printbal()
        sellerGoods.printbal()
        env.out.print("---Done---")

        //if we reach here, we can complete the transaction
        env.out.print("---moneyTransfer to sellerMoney from escrowMoney---")
        sellerMoney.deposit(price, escrowMoney)
        env.out.print("---Done---")

        env.out.print("---goodTransfer to buyerGoods from escrowGoods---")
        buyerGoods.deposit(amt, escrowGoods)
        env.out.print("---Done---")
        sellerMoney.printbal()
        sellerGoods.printbal()
        buyerMoney.printbal()
        buyerGoods.printbal()
        escrowMoney.printbal()
        escrowGoods.printbal()

        true
        


class Purse 
    let env: Env
    let name: String val
    let resource_type: String val
    let _childPurses: Array[Purse] ref
    var _qty: U32

    new create(env': Env, name': String, resource_type': String, qty':U32 = 0)=>
        env = env'
        name = name'
        resource_type = resource_type'
        _qty = qty'
        _childPurses = Array[Purse]
        printbal()
    fun ref sprout(): Purse =>
        let purse = Purse.create(env, "escrow_"+resource_type, resource_type)
        _childPurses.push(purse)
        purse
    fun ref zero() =>
        _qty = 0
        
    fun ref deposit(qty': U32, src': Purse):Bool val =>
        if (src'.withdraw(qty') is true) and (src'.resource_type is resource_type) then
            _qty = _qty + qty'
            return true
        end
        false

    fun ref withdraw(qty': U32):Bool val=>
        if (qty'<= _qty) then 
            _qty = _qty - qty'
            return true
        end 
        false

    fun printbal()=>
        env.out.print(name+": ("+resource_type+", "+_qty.string()+")")
