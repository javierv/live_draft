# encoding: utf-8

define_match :have_draft do |actual|
  actual.has_draft?
end

describe "Drafts" do
  context "Creating a new record" do
    let(:post) { Factory(:post) }

    it "isn't a draft by default" do
      post.draft = nil
      post.save
      post.draft.should == false 
    end

    it "can be set as a draft" do
      post.draft = true
      post.save
      post.draft.should == true 
    end
  end

  context "Creating a draft" do
    let(:post) { Factory(:post, title: "Original title") }

    context "with no previous draft" do
      specify { post.should_not have_draft }

      context "creating a new draft" do
        before do
          post.title = "Title has changed"
          post.save_draft
        end

        specify { post.should have_draft }

        it "creates a draft with the given attributes" do
          draft = post.draft
          draft.title.should == "Title has changed"
          draft.published_id.should == post.id
        end

        specify { post.draft.published.should == post }

        it "doesn't change the original record" do
          post.reload
          post.title.should == "Original title"
        end

        context "publishing the draft" do
          subject do
            post.draft.publish
            post.reload
            post
          end

          its(:title) { should == "Title has changed" }
          it { should_not have_draft }
        end

        context "publishing an invalid draft" do
          let(:draft) { post.draft }
          before(:each) do
            draft.title = ''
            @result = draft.publish
          end

          it "doesn't change the original record" do
            post.reload
            post.title.should == "Original title"
          end

          specify { post.should have_draft }
          specify { @result.should == false }
          specify { draft.should have(1).error_on(:title)
        end

        context "publishing a draft with given attributes" do
          before(:each) { post.draft.publish(title: "Parameter title") }

          it "updates the original record" do
            post.reload
            post.title.should == "Parameter title"
          end
        end
      end

      context "Creating a draft with parameters" do
        before(:each) { post.save_draft(title: "Parameter title") }
        specify { post.draft.title.should == "Parameter title" }
      end

      context "Creating an invalid draft" do
        before(:each) do
          post.title = ''
          post.save_draft
        end

        it "saves the draft" do
          post.should have_draft
          post.draft.title.should be_nil
        end
      end
    end

    context "with a previous draft" do
      before(:each) { post.save_draft }

      context "saving a new draft" do
        let(:title) {"New draft"}
        before(:each) do
          post.title = title
          post.save_draft
        end

        it "overwrites the previous draft" do
          post.draft.title.should == title
        end
      end
    end
  end

  context "a new draft with no original record" do
    let(:draft) { Post.new }
    before(:each) { draft.save_draft }

    it "saves the draft" do
      Post.where(title: '', draft: true).should be_true
    end

    it { draft.draft.should == draft }

    context "creating another draft" do
      before(:each) { Post.new.save_draft }

      it "doesn't overwrite the previous draft" do
        Post.where(draft: true).should have(2).items
      end
    end

    context "creating a new draft specifying the id" do
      let(:another_draft) { Post.new }
      before(:each) do
        another_draft.title = "Changed"
        another_draft.save_draft(draft: draft.draft.id)
      end

      it "overwrites the previous draft" do
        Post.where(draft: true).should have(1).item
        draft.draft.should == another_draft.draft
      end
    end
  end

  context "an existing draft with no original record" do
    let(:title) {"Initial draft"}
    subject { Factory(:post, draft: true, title: title) }

    it { should_not have_draft }
    its(:draft) { should == draft }

    context "publishing the draft" do
      before(:each) { subject.publish }
      let(:published) { Post.where(title: title, draft: false).first }

      it { published.should be_true }

      it "deletes the draft" do
        Post.where(title: title, draft: true).first.should be_false
      end

      its(:published) { should == published }
    end

    context "saving a draft" do
      before(:each) { subject.save_draft(title: "Title has changed") }
      its(:title) { should == "Title has changed" }
    end
  end
end
