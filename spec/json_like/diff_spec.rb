require 'json_like/diff'
describe JsonLike::Diff::Array do
  context "Empty" do
    subject{ JsonLike::Diff::Array.new([]) }
    it "prints nothing" do
      expect( subject.linearize ).to eql []
    end
  end

  context "Containing one redundant item" do
    subject{ JsonLike::Diff::Array.new([1]).redundant(0) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql [ '[', '1', ']' ]
    end
  end

  context "Containing one redundant item and multiple keys" do
    subject{ JsonLike::Diff::Array.new([1,2,3]).redundant(1) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['[','1,','2,','3',']']
    end
  end

  context "Containing one missing item and multiple keys" do
    subject{ JsonLike::Diff::Array.new([1,2,3]).missing(1, 10) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['[','1,','10,','2,','3',']']
    end
  end

  context "Containing one wrong item" do
    subject{ JsonLike::Diff::Array.new([1,[3],7]).wrong(1, JsonLike::Diff::Array.new([3]).missing(1,3)) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['[','1,','[','3,','3','],','7',']']
    end
  end
end

describe JsonLike::Diff::Hash do
  context "Empty" do
    subject{ JsonLike::Diff::Hash.new({}) }
    it "prints nothing" do
      expect( subject.linearize ).to eql []
    end
  end

  context "Containing one redundant item" do
    subject{ JsonLike::Diff::Hash.new({'key' => 1}).redundant('key') }
    it "prints the deletion" do
      expect( subject.linearize ).to eql [ '{', 'key: 1', '}' ]
    end
  end

  context "Containing one redundant item and multiple keys" do
    subject{ JsonLike::Diff::Hash.new({'a'=>1,'b'=>2,'c'=>3}).redundant('b') }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['{','a: 1,','b: 2,','c: 3','}']
    end
  end

  context "Containing one missing item and multiple keys" do
    subject{ JsonLike::Diff::Hash.new({'a' => 1, 'c' => 3}).missing('b', 2) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['{','a: 1,','b: 2,','c: 3','}']
    end
  end

  context "Containing one wrong item" do
    subject{ JsonLike::Diff::Hash.new({'key' => [3] }).wrong("key", JsonLike::Diff::Array.new([3]).missing(1,3)) }
    it "prints the deletion" do
      expect( subject.linearize ).to eql ['{','key: [','3,','3',']','}']
    end
  end
end
