# frozen_string_literal: true

require_relative "../spec_helper"

module CheckstyleReports::Entity
  FILE_NODE_SAMPLE_1 = <<NODE
<file
  name="/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java" >
  #{ERROR_NODE_SAMPLE_1}
</file>
NODE

  FILE_NODE_SAMPLE_2 = <<NODE
<file
  name="/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java" >
  #{ERROR_NODE_SAMPLE_1}
  #{ERROR_NODE_SAMPLE_2}
</file>
NODE

  FILE_NODE_SAMPLE_EMPTY = <<NODE
<file
  name="/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java" />
NODE

  describe CheckstyleReports::Entity::FoundFile do
    let(:file) { FoundFile.new(REXML::Document.new(node).elements.first) }

    context "sample1" do
      let(:node) { FILE_NODE_SAMPLE_1 }

      it "should read it successfully" do
        expect(file.path).to eq("/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java")
        expect(file.errors.size).to eq(1)
      end
    end

    context "sample2" do
      let(:node) { FILE_NODE_SAMPLE_2 }

      it "should read it successfully" do
        expect(file.path).to eq("/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java")
        expect(file.errors.size).to eq(2)
      end
    end

    context "sample empty" do
      let(:node) { FILE_NODE_SAMPLE_EMPTY }

      it "should read it successfully" do
        expect(file.path).to eq("/Users/jmatsu/Workspace/sample/src/java/io/github/jmatsu/Sample.java")
        expect(file.errors.size).to eq(0)
      end
    end
  end
end
