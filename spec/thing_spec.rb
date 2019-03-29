require 'spec_helper'
require 'rails_event_store/rspec'
require 'thing'

RSpec.describe Thing do
  specify do
    thing = Thing.new
    thing.submit

    expect(thing).to have_applied(an_event(ThingSubmitted))
  end

  specify do
    thing = Thing.new
    thing.submit
    thing.approve

    # following ignores other events in thing.unpublished_events
    # as long as ThingApproved is there
    expect(thing).to have_applied(an_event(ThingApproved))

    # following expects thing.unpublished_events to be exact match
    # expect(thing).to have_applied(an_event(ThingApproved)).strict
    expect(thing).to have_applied(
      an_event(ThingSubmitted),
      an_event(ThingApproved)
    ).strict
  end

  specify do
    # http://rspec.info/blog/2014/01/new-in-rspec-3-composable-matchers/
    # https://blog.arkency.com/composable-rspec-matchers/
    # also seen in page 179 of Domain-Driven Rails https://blog.arkency.com/domain-driven-rails/

    thing = Thing.new
    thing.submit

    # we rely on the fact that approve returns applied events,
    # as long as applying events is the last thing of the aggregate action
    expect(thing.approve).to match([event(ThingApproved)])
  end

  specify do
    with_events(ThingSubmitted.new) do |thing|
      thing.approve
      expect(thing).to have_applied(an_event(ThingApproved)).strict
    end
  end

  def event_store
    @event_store ||= RubyEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new
    )
  end

  def with_events(events, &block)
    event_store.append(events, stream_name: 'stream_for_a_thing')
    thing = Thing.new

    # Repository#load clears aggregates unpublished events
    # after they are applied on an aggregate
    AggregateRoot::Repository.new(event_store).load(thing, 'stream_for_a_thing')
    block.call(thing)
  end
end
