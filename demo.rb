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