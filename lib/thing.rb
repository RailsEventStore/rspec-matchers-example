require 'aggregate_root'
require 'ruby_event_store'

ThingSubmitted = Class.new(RubyEventStore::Event)
ThingApproved  = Class.new(RubyEventStore::Event)


class Thing
  include AggregateRoot

  def submit
    apply(ThingSubmitted.new)
  end

  def approve
    apply(ThingApproved.new)
  end

  on ThingSubmitted do |event|
    # ...
  end

  on ThingApproved do |event|
    # ...
  end
end
