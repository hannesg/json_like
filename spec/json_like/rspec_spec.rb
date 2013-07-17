require 'json_like/rspec'
describe JsonLike::RSpec do

  context "given an empty array to match" do
    subject do
      JsonLike::RSpec.matcher(<<JSONLIKE.chomp)
[]
JSONLIKE
    end

    it "matches an empty array" do
      expect( subject.matches?('[]') ).to be_true
    end

  end

  context "given an empty hash to match" do
    subject do
      JsonLike::RSpec.matcher(<<JSONLIKE.chomp)
{}
JSONLIKE
    end

    it "matches an empty hash" do
      expect( subject.matches?('{}') ).to be_true
    end

  end


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
      expect( subject.failure_message_for_should ).to eql <<STR.chomp
   [
++   "bar"
--   "foo"
   ]
STR
    end

    it "does not match an empty array" do
      expect( subject.matches?('[]') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR.chomp
   [
--   "foo"
   ]
STR
    end

    it "does not match something else" do
      expect( subject.matches?('"bar"') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR.chomp
++ "bar"
-- [
--   ...,
--   "foo",
--   ...
-- ]
STR
    end
  end

  context "given a hash to match" do

    subject do
      JsonLike::RSpec.matcher(<<JSONLIKE)
{
  foo: "bar",
  bar: ...  ,
  ...
}
JSONLIKE
    end

    it "matches a fitting hash" do
      expect( subject.matches?('{"foo":"bar","bar":1}') ).to be_true
    end

    it "does not match a wrong hash" do
      expect( subject.matches?('{"foo":"baz"}') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR.chomp
   {
--   bar: ...,
++   foo: "baz"
--     "bar"
   }
STR
    end

    it "does not match something else" do
      expect( subject.matches?('"foo"') ).to be_false
      expect( subject.failure_message_for_should ).to eql <<STR.chomp
++ "foo"
-- {
--   bar: ...,
--   foo: "bar",
--   ...
-- }
STR
    end
  end

end
