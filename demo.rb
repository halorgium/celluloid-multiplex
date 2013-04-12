class Router
  include Celluloid
  
  def initialize
    @children = {}
  end
  
  # on child exit, store the state
  
  def alive?(child)
    if child.alive?
      @children.fetch(child.mailbox).sync(:alive?)
    else
      @cache.fetch(child.mailbox).fetch(:alive?)
    end
  end
  
  def register(child)
    @children[child.mailbox] = child
    RouterProxy.new(current_actor, child)
  end
end

class RouterProxy < Celluloid::AbstractProxy
  def initialize(router, child)
    @child = child
    @proxy = SyncProxy.new(router.mailbox, router.class)
  end

  def method_missing(meth, *args, &block)
    args.unshift @child
    @proxy.method_missing(meth, *args, &block)
  end
end

router = Router.new
child = router.register(Child.new) # RouterProxy

child.alive? # router.alive?(Raw(child))