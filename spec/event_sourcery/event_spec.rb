RSpec.describe EventSourcery::Event do
  let(:aggregate_id) { 'aggregate_id' }
  let(:type) { 'type' }
  let(:version) { 1 }
  let(:body) do
    {
      symbol: "value",
    }
  end
  let(:uuid) { SecureRandom.uuid }

  describe '#initialize' do
    subject(:initializer) { described_class.new(aggregate_id: aggregate_id, type: type, body: body, version: version) }

    before do
      allow(EventSourcery::EventBodySerializer).to receive(:serialize)
    end

    it 'serializes event body' do
      expect(EventSourcery::EventBodySerializer).to receive(:serialize).with(body)
      initializer
    end

    it 'assigns a uuid if one is not given' do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      expect(initializer.uuid).to eq uuid
    end

    it 'assigns given uuids' do
      uuid = SecureRandom.uuid
      expect(described_class.new(uuid: uuid).uuid).to eq uuid
    end

    context 'event body is nil' do
      let(:body) { nil }

      it 'skips serialization of event body' do
        expect(EventSourcery::EventBodySerializer).to_not receive(:serialize)
        initializer
      end
    end

    context 'given version is a long string' do
      let(:version) { '1' * 20 }

      it 'version type is coerced to an integer value, bignum style' do
        expect(initializer.version).to eq(11_111_111_111_111_111_111)
      end
    end
  end

  describe '.type' do
    let(:serializer) { double }

    before do
      allow(EventSourcery.config).to receive(:event_type_serializer).and_return(serializer)
      allow(serializer).to receive(:serialize).and_return('serialized')
    end

    it 'delegates to the configured event type serializer' do
      ItemAdded.type
      expect(serializer).to have_received(:serialize).with(ItemAdded)
    end

    it 'returns the serialized type' do
      expect(ItemAdded.type).to eq('serialized')
    end

    context 'when the event is EventSourcery::Event' do
      it 'returns nil' do
        expect(EventSourcery::Event.type).to be_nil
      end
    end
  end

  describe '#type' do
    before do
      allow(EventSourcery::Event).to receive(:type).and_return(type)
    end

    context 'when the event class type is nil' do
      let(:type) { nil }

      it 'uses the provided type' do
        event = EventSourcery::Event.new(type: 'blah')
        expect(event.type).to eq 'blah'
      end
    end

    context 'when the event class type is not nil' do
      let(:type) { 'ItemAdded' }

      it "can't be overridden with the provided type" do
        event = EventSourcery::Event.new(type: 'blah')
        expect(event.type).to eq 'ItemAdded'
      end
    end
  end
end
