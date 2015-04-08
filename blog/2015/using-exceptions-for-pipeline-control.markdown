Date: 2015-03-26  
Status: Draft  
Tags: Exceptions, Design Patterns, Monads  

# Using exceptions for pipeline control

The rule "[don't use exceptions for flow control](http://c2.com/cgi/wiki?DontUseExceptionsForFlowControl)" is one of the first that many programmers learn. Like so many rules in programming it sounds nice and simple, and you can apply it by simply avoiding exceptions as much as possible.

But is that really the right thing to do? I'm going to argue that in a significant number of languages exceptions are the primary means of function composition, and that by avoiding them you're making life much harder than it should be.

## Flow control

What people typically mean when they recommend against using exceptions for flow control is that you shouldn't write insane code like this:

~~~ruby
a = [1, 2, 3, 4, 5]
i = 0
begin
  loop do
    puts a.fetch(i)
  end
rescue IndexError
end
~~~

When there's a more elegant solution like this:

~~~ruby
a = [1, 2, 3, 4, 5]
a.each do { |n| puts n }
~~~

(And yeah, I know you could also just write `puts *a` but I was trying to illustrate a better looping approach.)

This is almost always good advice -- with rare exceptions such as breaking out of deeply nested loops or recursive functions where an unconditional jump out of the deepest level can be the cleanest way to return -- because the code is normally easier to read without exceptions.

However, there's a difference between something like this where you're simply executing code that _can't_ fail, and other code that performs a sequence of actions that _might_ fail at any stage.

## Pipeline control

** Pipeline control is different (success channel diagram)


### Explicit pipeline control

~~~c
int place_order(order *order, credit_card *card) {
    int err = save_order(order);
    if (err == 0) {
        err = charge_credit_card(card, order->total);
        if (err == 0) {
            err = update_order_status(order, PAID);
        }
    }
    return err;
}
~~~

### Monadic pipeline control

~~~scala
sealed trait Try[+T]
case class Success[+T](result: T) extends Try[T]
case class Failure[+T](error: Exception) extends Try[T]
~~~

~~~scala
def placeOrder(order: Order, card: CreditCard): Try[Unit] = {
  for { 
    _ <- saveOrder(order)
    _ <- chargeCreditCard(card, order.total)
    _ <- updateOrderStatus(order, Paid)
  } yield ()
}
~~~

### Exceptional pipeline control

~~~ruby
def place_order!(order, card)
  save_order!(order)
  charge_credit_card!(card, order.total)
  update_order_status!(order, :paid)
end
~~~




