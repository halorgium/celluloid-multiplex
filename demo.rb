require 'celluloid'

class Child
  include Celluloid

  def initialize
    @counter = 0
  end
  attr_reader :counter

  def incr
    @counter += 1
  end

  # reply with state
  def finish
    {
      :counter => @counter,
    }
  end
end

class Router
  include Celluloid

  def initialize
    @cache = {}
    @children = {}
  end

  trap_exit :on_exit

  def counter(mailbox)
    if @cache.key?(mailbox)
      @cache.fetch(mailbox).fetch(:counter)
    else
      @children.fetch(mailbox).sync(:counter)
    end
  end

  def incr(mailbox)
    @children.fetch(mailbox).sync(:incr)
  end

  def start_child
    child = Child.new_link
    @children[child.mailbox] = child
    RouterProxy.new(current_actor, child)
  end

  def finish(mailbox)
    data = @children.fetch(mailbox).sync(:finish)
    @cache[mailbox] = data
    @children.fetch(mailbox).terminate
  end

  def on_exit(actor, reason)
    @children.delete(actor.mailbox)
  end
end

class RouterProxy < Celluloid::AbstractProxy
  def initialize(router, child)
    @child = child.mailbox
    @proxy = ::Celluloid::SyncProxy.new(router.mailbox, router.class)
  end

  def method_missing(meth, *args, &block)
    args.unshift @child
    @proxy.method_missing(meth, *args, &block)
  end
end

router = Router.new
child = router.start_child

p(actors: Celluloid::Actor.all.size)
p(counter: child.counter)
p(incr: child.incr)
p(counter: child.counter)
p(finish: child.finish)
p(actors: Celluloid::Actor.all.size)
p(counter: child.counter)
