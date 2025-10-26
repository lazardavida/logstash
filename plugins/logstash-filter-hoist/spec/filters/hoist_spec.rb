require 'spec_helper'
require "logstash/filters/hoist"

describe LogStash::Filters::Hoist do
  let(:config) { { "source" => "nested" } }
  subject { described_class.new(config) }

  before do
    subject.register
  end

  describe "#filter" do
    let(:attrs) { {} }
    let(:event) { LogStash::Event.new(attrs) }

    before do
      subject.filter(event)
    end

    context "when source field is missing" do
      let(:attrs) { { "other" => "value" } }

      it "leaves event unchanged" do
        expect(event.get("other")).to eq("value")
        expect(event.to_hash.keys).not_to include("tags")
      end
    end

    context "when source field is not a hash" do
      let(:attrs) { { "nested" => "not a hash" } }

      it "tags event with _hoisterror" do
        expect(event.get("tags")).to include("_hoisterror")
      end

      it "leaves source field unchanged" do
        expect(event.get("nested")).to eq("not a hash")
      end
    end

    context "when source field is empty hash" do
      let(:attrs) { { "nested" => {} } }

      it "processes event without error" do
        expect(event.get("nested")).to eq({})
      end
    end

    context "when source field contains nested properties" do
      let(:attrs) { { "nested" => { "field1" => "value1", "field2" => "value2" } } }

      it "hoists properties to root level" do
        expect(event.get("field1")).to eq("value1")
        expect(event.get("field2")).to eq("value2")
      end

      it "keeps source field by default" do
        expect(event.get("nested")).to eq({ "field1" => "value1", "field2" => "value2" })
      end
    end

    context "with remove_source => true" do
      let(:config) { { "source" => "nested", "remove_source" => true } }
      let(:attrs) { { "nested" => { "field1" => "value1" } } }

      it "removes source field after hoisting" do
        expect(event.get("field1")).to eq("value1")
        expect(event.include?("nested")).to be false
      end
    end

    context "with overwrite => false (default)" do
      let(:attrs) { { 
        "nested" => { "field1" => "new_value" },
        "field1" => "existing_value"
      } }

      it "does not overwrite existing fields" do
        expect(event.get("field1")).to eq("existing_value")
      end
    end

    context "with overwrite => true" do
      let(:config) { { "source" => "nested", "overwrite" => true } }
      let(:attrs) { { 
        "nested" => { "field1" => "new_value" },
        "field1" => "existing_value"
      } }

      it "overwrites existing fields" do
        expect(event.get("field1")).to eq("new_value")
      end
    end

    context "with remove_source => true and overwrite => false" do
      let(:config) { { 
        "source" => "nested", 
        "remove_source" => true,
        "overwrite" => false
      } }
      let(:attrs) { { 
        "nested" => { 
          "field1" => "new_value",
          "field2" => "value2"
        },
        "field1" => "existing_value"
      } }

      it "keeps fields that would overwrite in source" do
        expect(event.get("nested")).to eq({ "field1" => "new_value" })
        expect(event.get("field1")).to eq("existing_value")
        expect(event.get("field2")).to eq("value2")
      end
    end
  end
end