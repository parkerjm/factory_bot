describe "an instance generated by a factory with multiple traits" do
  before do
    define_model("Post",
                 name:          :string,
                 admin:         :boolean,
                 gender:        :string,
                 email:         :string,
                 published_at:  :date,
                 great:         :string)

    FactoryBot.define do
      factory :post_without_admin_scoping, class: Post do
        admin_trait
      end

      factory :post do
        name { "John" }

        trait :great do
          great { "GREAT!!!" }
        end

        trait :admin do
          admin { true }
        end

        trait :admin_trait do
          admin { true }
        end

        trait :male do
          name   { "Joe" }
          gender { "Male" }
        end

        trait :female do
          name   { "Jane" }
          gender { "Female" }
        end

        factory :great_post do
          great
        end

        factory :admin, traits: [:admin]

        factory :male_post do
          male

          factory :child_male_post do
            published_at { Date.parse("1/1/2000") }
          end
        end

        factory :female, traits: [:female] do
          trait :admin do
            admin { true }
            name { "Judy" }
          end

          factory :female_great_post do
            great
          end

          factory :female_admin_judy, traits: [:admin]
        end

        factory :female_admin,            traits: [:female, :admin]
        factory :female_after_male_admin, traits: [:male, :female, :admin]
        factory :male_after_female_admin, traits: [:female, :male, :admin]
      end

      trait :email do
        email { "#{name}@example.com" }
      end

      factory :post_with_email, class: Post, traits: [:email] do
        name { "Bill" }
      end
    end
  end

  context "the parent class" do
    subject      { FactoryBot.create(:post) }
    its(:name)   { should eq "John" }
    its(:gender) { should be_nil }
    it           { should_not be_admin }
  end

  context "the child class with one trait" do
    subject      { FactoryBot.create(:admin) }
    its(:name)   { should eq "John" }
    its(:gender) { should be_nil }
    it           { should be_admin }
  end

  context "the other child class with one trait" do
    subject      { FactoryBot.create(:female) }
    its(:name)   { should eq "Jane" }
    its(:gender) { should eq "Female" }
    it           { should_not be_admin }
  end

  context "the child with multiple traits" do
    subject      { FactoryBot.create(:female_admin) }
    its(:name)   { should eq "Jane" }
    its(:gender) { should eq "Female" }
    it           { should be_admin }
  end

  context "the child with multiple traits and overridden attributes" do
    subject      { FactoryBot.create(:female_admin, name: "Jill", gender: nil) }
    its(:name)   { should eq "Jill" }
    its(:gender) { should be_nil }
    it           { should be_admin }
  end

  context "the child with multiple traits who override the same attribute" do
    context "when the male assigns name after female" do
      subject      { FactoryBot.create(:male_after_female_admin) }
      its(:name)   { should eq "Joe" }
      its(:gender) { should eq "Male" }
      it           { should be_admin }
    end

    context "when the female assigns name after male" do
      subject      { FactoryBot.create(:female_after_male_admin) }
      its(:name)   { should eq "Jane" }
      its(:gender) { should eq "Female" }
      it           { should be_admin }
    end
  end

  context "child class with scoped trait and inherited trait" do
    subject      { FactoryBot.create(:female_admin_judy) }
    its(:name)   { should eq "Judy" }
    its(:gender) { should eq "Female" }
    it           { should be_admin }
  end

  context "factory using global trait" do
    subject     { FactoryBot.create(:post_with_email) }
    its(:name)  { should eq "Bill" }
    its(:email) { should eq "Bill@example.com" }
  end

  context "factory created with alternate syntax for specifying trait" do
    subject      { FactoryBot.create(:male_post) }
    its(:gender) { should eq "Male" }

    context "where trait name and attribute are the same" do
      subject     { FactoryBot.create(:great_post) }
      its(:great) { should eq "GREAT!!!" }
    end

    context "where trait name and attribute are the same and attribute is overridden" do
      subject     { FactoryBot.create(:great_post, great: "SORT OF!!!") }
      its(:great) { should eq "SORT OF!!!" }
    end
  end

  context "child factory created where trait attributes are inherited" do
    subject             { FactoryBot.create(:child_male_post) }
    its(:gender)        { should eq "Male" }
    its(:published_at)  { should eq Date.parse("1/1/2000") }
  end

  context "factory outside of scope" do
    subject { FactoryBot.create(:post_without_admin_scoping) }

    it "raises an error" do
      expect { subject }.
        to raise_error(KeyError, "Trait not registered: \"admin_trait\"")
    end
  end

  context "child factory using grandparents' trait" do
    subject     { FactoryBot.create(:female_great_post) }
    its(:great) { should eq "GREAT!!!" }
  end
end

describe "trait indifferent access" do
  context "when trait is defined as a string" do
    it "can be invoked with a string" do
      build_post_factory_with_admin_trait("admin")

      post = FactoryBot.build(:post, "admin")

      expect(post).to be_admin
    end

    it "can be invoked with a symbol" do
      build_post_factory_with_admin_trait("admin")

      post = FactoryBot.build(:post, :admin)

      expect(post).to be_admin
    end
  end

  context "when trait is defined as a symbol" do
    it "can be invoked with a string" do
      build_post_factory_with_admin_trait(:admin)

      post = FactoryBot.build(:post, "admin")

      expect(post).to be_admin
    end

    it "can be invoked with a symbol" do
      build_post_factory_with_admin_trait(:admin)

      post = FactoryBot.build(:post, :admin)

      expect(post).to be_admin
    end
  end

  def build_post_factory_with_admin_trait(trait_name)
    define_model("Post", admin: :boolean)

    FactoryBot.define do
      factory :post do
        admin { false }

        trait trait_name do
          admin { true }
        end
      end
    end
  end
end

describe "looking up traits that don't exist" do
  it "raises a KeyError" do
    define_class("Post")

    FactoryBot.define do
      factory :post
    end

    expect { FactoryBot.build(:post, double("not a trait")) }.
      to raise_error(KeyError)
  end
end

describe "traits with callbacks" do
  before do
    define_model("Post", name: :string)

    FactoryBot.define do
      factory :post do
        name { "John" }

        trait :great do
          after(:create) { |post| post.name.upcase! }
        end

        trait :awesome do
          after(:create) { |post| post.name = "awesome" }
        end

        factory :caps_post, traits: [:great]
        factory :awesome_post, traits: [:great, :awesome]

        factory :caps_post_implicit_trait do
          great
        end
      end
    end
  end

  context "when the factory has a trait passed via arguments" do
    subject    { FactoryBot.create(:caps_post) }
    its(:name) { should eq "JOHN" }
  end

  context "when the factory has an implicit trait" do
    subject    { FactoryBot.create(:caps_post_implicit_trait) }
    its(:name) { should eq "JOHN" }
  end

  it "executes callbacks in the order assigned" do
    expect(FactoryBot.create(:awesome_post).name).to eq "awesome"
  end
end

describe "traits added via strategy" do
  before do
    define_model("Post", name: :string, admin: :boolean)

    FactoryBot.define do
      factory :post do
        name { "John" }

        trait :admin do
          admin { true }
        end

        trait :great do
          after(:create) { |post| post.name.upcase! }
        end
      end
    end
  end

  context "adding traits in create" do
    subject { FactoryBot.create(:post, :admin, :great, name: "Joe") }

    its(:admin) { should be true }
    its(:name)  { should eq "JOE" }

    it "doesn't modify the post factory" do
      subject
      expect(FactoryBot.create(:post)).not_to be_admin
      expect(FactoryBot.create(:post).name).to eq "John"
    end
  end

  context "adding traits in build" do
    subject { FactoryBot.build(:post, :admin, :great, name: "Joe") }

    its(:admin) { should be true }
    its(:name)  { should eq "Joe" }
  end

  context "adding traits in attributes_for" do
    subject { FactoryBot.attributes_for(:post, :admin, :great) }

    its([:admin]) { should be true }
    its([:name])  { should eq "John" }
  end

  context "adding traits in build_stubbed" do
    subject { FactoryBot.build_stubbed(:post, :admin, :great, name: "Jack") }

    its(:admin) { should be true }
    its(:name)  { should eq "Jack" }
  end

  context "adding traits in create_list" do
    subject { FactoryBot.create_list(:post, 2, :admin, :great, name: "Joe") }

    its(:length) { should eq 2 }

    it "creates all the records" do
      subject.each do |record|
        expect(record.admin).to be true
        expect(record.name).to eq "JOE"
      end
    end
  end

  context "adding traits in build_list" do
    subject { FactoryBot.build_list(:post, 2, :admin, :great, name: "Joe") }

    its(:length) { should eq 2 }

    it "builds all the records" do
      subject.each do |record|
        expect(record.admin).to be true
        expect(record.name).to eq "Joe"
      end
    end
  end
end

describe "traits and dynamic attributes that are applied simultaneously" do
  before do
    define_model("Post", name: :string, email: :string, combined: :string)

    FactoryBot.define do
      trait :email do
        email { "#{name}@example.com" }
      end

      factory :post do
        name { "John" }
        email
        combined { "#{name} <#{email}>" }
      end
    end
  end

  subject        { FactoryBot.build(:post) }
  its(:name)     { should eq "John" }
  its(:email)    { should eq "John@example.com" }
  its(:combined) { should eq "John <John@example.com>" }
end

describe "applying inline traits" do
  before do
    define_model("Post") do
      has_many :tags
    end

    define_model("Tag", post_id: :integer) do
      belongs_to :post
    end

    FactoryBot.define do
      factory :post do
        trait :with_tags do
          tags { [Tag.new] }
        end
      end
    end
  end

  it "applies traits only to the instance generated for that call" do
    expect(FactoryBot.create(:post, :with_tags).tags).not_to be_empty
    expect(FactoryBot.create(:post).tags).to be_empty
    expect(FactoryBot.create(:post, :with_tags).tags).not_to be_empty
  end
end

describe "inline traits overriding existing attributes" do
  before do
    define_model("Post", status: :string)

    FactoryBot.define do
      factory :post do
        status { "pending" }

        trait(:accepted) { status { "accepted" } }
        trait(:declined) { status { "declined" } }

        factory :declined_post, traits: [:declined]
        factory :extended_declined_post, traits: [:declined] do
          status { "extended_declined" }
        end
      end
    end
  end

  it "returns the default status" do
    expect(FactoryBot.build(:post).status).to eq "pending"
  end

  it "prefers inline trait attributes over default attributes" do
    expect(FactoryBot.build(:post, :accepted).status).to eq "accepted"
  end

  it "prefers traits on a factory over default attributes" do
    expect(FactoryBot.build(:declined_post).status).to eq "declined"
  end

  it "prefers inline trait attributes over traits on a factory" do
    expect(FactoryBot.build(:declined_post, :accepted).status).to eq "accepted"
  end

  it "prefers attributes on factories over attributes from non-inline traits" do
    expect(FactoryBot.build(:extended_declined_post).status).to eq "extended_declined"
  end

  it "prefers inline traits over attributes on factories" do
    expect(FactoryBot.build(:extended_declined_post, :accepted).status).to eq "accepted"
  end

  it "prefers overridden attributes over attributes from traits, inline traits, or attributes on factories" do
    post = FactoryBot.build(:extended_declined_post, :accepted, status: "completely overridden")

    expect(post.status).to eq "completely overridden"
  end
end

describe "making sure the factory is properly compiled the first time we want to instantiate it" do
  before do
    define_model("Post", role: :string, gender: :string, age: :integer)

    FactoryBot.define do
      factory :post do
        trait(:female) { gender { "female" } }
        trait(:admin) { role { "admin" } }

        factory :female_post do
          female
        end
      end
    end
  end

  it "can honor traits on the very first call" do
    post = FactoryBot.build(:female_post, :admin, age: 30)
    expect(post.gender).to eq "female"
    expect(post.age).to eq 30
    expect(post.role).to eq "admin"
  end
end

describe "traits with to_create" do
  before do
    define_model("Post", name: :string)

    FactoryBot.define do
      factory :post do
        trait :with_to_create do
          to_create { |instance| instance.name = "to_create" }
        end

        factory :sub_post do
          to_create { |instance| instance.name = "sub" }

          factory :child_post
        end

        factory :sub_post_with_trait do
          with_to_create

          factory :child_post_with_trait
        end

        factory :sub_post_with_trait_and_override do
          with_to_create
          to_create { |instance| instance.name = "sub with trait and override" }

          factory :child_post_with_trait_and_override
        end
      end
    end
  end

  it "can apply to_create from traits" do
    expect(FactoryBot.create(:post, :with_to_create).name).to eq "to_create"
  end

  it "can apply to_create from the definition" do
    expect(FactoryBot.create(:sub_post).name).to eq "sub"
    expect(FactoryBot.create(:child_post).name).to eq "sub"
  end

  it "gives additional traits higher priority than to_create from the definition" do
    expect(FactoryBot.create(:sub_post, :with_to_create).name).to eq "to_create"
    expect(FactoryBot.create(:child_post, :with_to_create).name).to eq "to_create"
  end

  it "gives base traits normal priority" do
    expect(FactoryBot.create(:sub_post_with_trait).name).to eq "to_create"
    expect(FactoryBot.create(:child_post_with_trait).name).to eq "to_create"
  end

  it "gives base traits lower priority than overrides" do
    expect(FactoryBot.create(:sub_post_with_trait_and_override).name).to eq "sub with trait and override"
    expect(FactoryBot.create(:child_post_with_trait_and_override).name).to eq "sub with trait and override"
  end

  it "gives additional traits higher priority than base traits and factory definition" do
    FactoryBot.define do
      trait :overridden do
        to_create { |instance| instance.name = "completely overridden" }
      end
    end

    sub_post = FactoryBot.create(:sub_post_with_trait_and_override, :overridden)
    child_post = FactoryBot.create(:child_post_with_trait_and_override, :overridden)
    expect(sub_post.name).to eq "completely overridden"
    expect(child_post.name).to eq "completely overridden"
  end
end

describe "traits with initialize_with" do
  before do
    define_class("Post") do
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    FactoryBot.define do
      factory :post do
        trait :with_initialize_with do
          initialize_with { new("initialize_with") }
        end

        factory :sub_post do
          initialize_with { new("sub") }

          factory :child_post
        end

        factory :sub_post_with_trait do
          with_initialize_with

          factory :child_post_with_trait
        end

        factory :sub_post_with_trait_and_override do
          with_initialize_with
          initialize_with { new("sub with trait and override") }

          factory :child_post_with_trait_and_override
        end
      end
    end
  end

  it "can apply initialize_with from traits" do
    expect(FactoryBot.build(:post, :with_initialize_with).name).to eq "initialize_with"
  end

  it "can apply initialize_with from the definition" do
    expect(FactoryBot.build(:sub_post).name).to eq "sub"
    expect(FactoryBot.build(:child_post).name).to eq "sub"
  end

  it "gives additional traits higher priority than initialize_with from the definition" do
    expect(FactoryBot.build(:sub_post, :with_initialize_with).name).to eq "initialize_with"
    expect(FactoryBot.build(:child_post, :with_initialize_with).name).to eq "initialize_with"
  end

  it "gives base traits normal priority" do
    expect(FactoryBot.build(:sub_post_with_trait).name).to eq "initialize_with"
    expect(FactoryBot.build(:child_post_with_trait).name).to eq "initialize_with"
  end

  it "gives base traits lower priority than overrides" do
    expect(FactoryBot.build(:sub_post_with_trait_and_override).name).to eq "sub with trait and override"
    expect(FactoryBot.build(:child_post_with_trait_and_override).name).to eq "sub with trait and override"
  end

  it "gives additional traits higher priority than base traits and factory definition" do
    FactoryBot.define do
      trait :overridden do
        initialize_with { new("completely overridden") }
      end
    end

    sub_post = FactoryBot.build(:sub_post_with_trait_and_override, :overridden)
    child_post = FactoryBot.build(:child_post_with_trait_and_override, :overridden)
    expect(sub_post.name).to eq "completely overridden"
    expect(child_post.name).to eq "completely overridden"
  end
end

describe "nested implicit traits" do
  before do
    define_class("Post") do
      attr_accessor :gender, :role
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end

  shared_examples_for "assigning data from traits" do
    it "assigns the correct values" do
      post = FactoryBot.create(:post, :female_admin)
      expect(post.gender).to eq "FEMALE"
      expect(post.role).to eq "ADMIN"
      expect(post.name).to eq "Jane Doe"
    end
  end

  context "defined outside the factory" do
    before do
      FactoryBot.define do
        trait :female do
          gender { "female" }
          to_create { |instance| instance.gender = instance.gender.upcase }
        end

        trait :jane_doe do
          initialize_with { new("Jane Doe") }
        end

        trait :admin do
          role { "admin" }
          after(:build) { |instance| instance.role = instance.role.upcase }
        end

        trait :female_admin do
          female
          admin
          jane_doe
        end

        factory :post
      end
    end

    it_should_behave_like "assigning data from traits"
  end

  context "defined inside the factory" do
    before do
      FactoryBot.define do
        factory :post do
          trait :female do
            gender { "female" }
            to_create { |instance| instance.gender = instance.gender.upcase }
          end

          trait :jane_doe do
            initialize_with { new("Jane Doe") }
          end

          trait :admin do
            role { "admin" }
            after(:build) { |instance| instance.role = instance.role.upcase }
          end

          trait :female_admin do
            female
            admin
            jane_doe
          end
        end
      end
    end

    it_should_behave_like "assigning data from traits"
  end
end

describe "implicit traits containing callbacks" do
  before do
    define_model("Post", value: :integer)

    FactoryBot.define do
      factory :post do
        value { 0 }

        trait :trait_with_callback do
          after(:build) { |post| post.value += 1 }
        end

        factory :post_with_trait_with_callback do
          trait_with_callback
        end
      end
    end
  end

  it "only runs the callback once" do
    expect(FactoryBot.build(:post_with_trait_with_callback).value).to eq 1
  end
end

describe "traits used in associations" do
  before do
    define_model("Post", published: :boolean, name: :string)

    define_model("Comment", post_id: :integer) do
      belongs_to :post
    end

    define_model("Order", creator_id: :integer) do
      belongs_to :creator, class_name: "Post"
    end

    define_model("Image", post_id: :integer) do
      belongs_to :post, class_name: "Post"
    end

    FactoryBot.define do
      factory :post do
        published { false }

        trait :published do
          published { true }
        end
      end

      factory :image do
        association :post, factory: [:post, :published], name: "John Doe"
      end

      factory :comment do
        association :post, :published, name: "Joe Slick"
      end

      factory :order do
        association :creator, :published, factory: :post, name: "Joe Creator"
      end
    end
  end

  it "allows assigning traits for the factory of an association" do
    post = FactoryBot.create(:image).post
    expect(post).to be_published
    expect(post.name).to eq "John Doe"
  end

  it "allows inline traits with the default association" do
    post = FactoryBot.create(:comment).post
    expect(post).to be_published
    expect(post.name).to eq "Joe Slick"
  end

  it "allows inline traits with a specific factory for an association" do
    creator = FactoryBot.create(:order).creator
    expect(creator).to be_published
    expect(creator.name).to eq "Joe Creator"
  end
end
