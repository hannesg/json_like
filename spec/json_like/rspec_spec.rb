require 'json_like/rspec'
describe JsonLike::RSpec::ArrayMatcher do

  context "empty" do
    subject{ JsonLike::RSpec::ArrayMatcher.new() }

    it "matches an empty array" do
      expect( subject.matches?([]) ).to be_true
    end

    it "does not match an array with one element" do
      expect( subject.matches?([1]) ).to be_false
    end
  end

  context "with one single matcher" do
    subject{ JsonLike::RSpec::ArrayMatcher.new([JsonLike::RSpec::SimpleMatcher.new(1)]) }

    it "does not match an empty array" do
      expect( subject.matches?([]) ).to be_false
    end

    it "matches an array with the right element" do
      expect( subject.matches?([1]) ).to be_true
    end

    it "does not match an array containing the wrong element" do
      expect( subject.matches?([2]) ).to be_false
    end

    it "does not match an array of wrong size" do
      expect( subject.matches?([1,2]) ).to be_false
    end
  end

  context "with one multiple matcher" do
    subject{ JsonLike::RSpec::ArrayMatcher.new([JsonLike::RSpec::Ellipsis.new]) }

    it "matches an empty array" do
      expect( subject.matches?([]) ).to be_true
    end

    it "matches an array with one element" do
      expect( subject.matches?([1]) ).to be_true
    end
  end

  context "with a single and a multiple matcher" do

    subject{ JsonLike::RSpec::ArrayMatcher.new(
       [JsonLike::RSpec::SimpleMatcher.new(1), JsonLike::RSpec::Ellipsis.new]
    ) }

    it "does not match an empty array" do
      expect( subject.matches?([]) ).to be_false
    end

    it "matches an array with the right element" do
      expect( subject.matches?([1]) ).to be_true
    end

    it "does not match an array containing the wrong element" do
      expect( subject.matches?([2]) ).to be_false
    end

    it "matches an array with additional elements" do
      expect( subject.matches?([1,2]) ).to be_true
    end
  end

end

describe JsonLike::RSpec do

  context "given an array to match" do
    subject do
      JsonLike::RSpec.matcher(<<JSONLIKE.chomp)
[ ..., "foo", ... ]
JSONLIKE
    end

    it "matches a fitting array" do
      expect( subject.matches?('["foo"]') ).to be_true
    end

    it "does not match a wrong array" do
      expect( subject.matches?('["bar"]') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR

expected: "foo"
     got: "bar"

(compared using ==)
STR
    end

    it "does not match an empty array" do
      expect( subject.matches?('[]') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR

expected: more items
     got: none
STR
    end

    it "does not match something else" do
      expect( subject.matches?('"bar"') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR

expected: an array
     got: "bar"
STR
    end
  end

end
