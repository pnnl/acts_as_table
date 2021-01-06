# ActsAsTable

This is a Ruby on Rails plugin for working with tabular data.

* https://github.com/pnnl/acts_as_table

## Documentation

### ActsAsTable Table Specification Models

* {ActsAsTable::ColumnModel}
* {ActsAsTable::RowModel}

### ActsAsTable Record Specification Models

* {ActsAsTable::BelongsTo}
* {ActsAsTable::ForeignKey}
* {ActsAsTable::ForeignKeyMap}
* {ActsAsTable::HasMany}
* {ActsAsTable::HasManyTarget}
* {ActsAsTable::Lense}
* {ActsAsTable::PrimaryKey}
* {ActsAsTable::RecordModel}
* {ActsAsTable::RecordModelClassMethods} (concern)
* {ActsAsTable::ValueProvider} (concern)
* {ActsAsTable::ValueProviderAssociationMethods} (concern)

### ActsAsTable Table/Record Storage Models

* {ActsAsTable::Record}
* {ActsAsTable::RecordError}
* {ActsAsTable::Table}
* {ActsAsTable::Value}

### ActsAsTable Serialization

* {ActsAsTable::Headers}
  * {ActsAsTable::Headers::Array}
  * {ActsAsTable::Headers::Hash}
* {ActsAsTable::Reader}
* {ActsAsTable::Writer}

### ActsAsTable Serialization Formats

* [ActsAsTable::CSV](https://github.com/pnnl/acts_as_table_csv) (extension)

### ActsAsTable Utilities

* {ActsAsTable::Adapter}
* {ActsAsTable::Configuration}
* {ActsAsTable::Mapper}
  * {ActsAsTable::Mapper::Base}
  * {ActsAsTable::Mapper::BelongsTo}
  * {ActsAsTable::Mapper::ForeignKey}
  * {ActsAsTable::Mapper::HasAndBelongsToMany}
  * {ActsAsTable::Mapper::HasMany}
  * {ActsAsTable::Mapper::HasOne}
  * {ActsAsTable::Mapper::Lense}
  * {ActsAsTable::Mapper::PrimaryKey}
  * {ActsAsTable::Mapper::RecordModel}
  * {ActsAsTable::Mapper::RowModel}
* {ActsAsTable::Path}

## Dependencies

* [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) (>= 4.2, < 6.1)

## Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest, official release of the ActsAsTable gem, do:
```bash
% [sudo] gem install acts_as_table
```

### Install ActsAsTable Migrations

If the ActsAsTable gem is being used as part of a Ruby on Rails application, do:

```bash
% rake acts_as_table:install:migrations
```

See documentation for {ActsAsTable.configure} for example of modifying the table names for the ActsAsTable model classes.

```bash
% rake db:migrate
```

## Examples

```ruby
require 'acts_as_table'
```

### Table/Record Specification for Preexisting Ruby on Rails Application

The preexisting Ruby on Rails application has the following model classes:

* `app/models/blog.rb`

```ruby
class Blog < ActiveRecord::Base
  validates_presence_of :title

  belongs_to :user, required: true

  has_many :posts
end
```

* `app/models/post.rb`

```ruby
class Post < ActiveRecord::Base
  validates_presence_of :title, :abstract

  belongs_to :blog, required: true
end
```

* `app/models/user.rb`

```ruby
class User < ActiveRecord::Base
  validates_presence_of :login, :email

  has_many :blogs
end
```

The goal is to specify a table of instances of the `Post` class with the following structure:

| Protected | Protected | Public | Public | Public | Public | Public |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| User | User | Blog | Post | Post | Post | Post |
| Login Screen Name | Email Address | Title | Title | Abstract | Date Created | Date Modified |
| `post.blog.user.login` | `post.blog.user.email` | `post.blog.title` | `post.title` | `post.abstract` | `post.created_at` | `post.updated_at` |

The table has 3 header rows (viz., the metadata).

The non-header rows (viz., the data) correspond to arrays of Ruby objects (viz., the values), where the elements of the array are obtained by traversing paths of ActiveRecord associations that terminate with ActiveRecord columns or Ruby attribute accessors.

For example, the value of the "Protected,User,Login Screen Name" column is obtained by traversing the following path: `Post#blog` &rarr; `Blog#user` &rarr; `User#login`.

Multi-level headers (of arbitrary depth) and corresponding paths are specified using the {ActsAsTable::Path} class.

For example, the "Protected,User,Login Screen Name" is specified as follows:
```ruby
{
  'Protected' => {
    'User' => {
      'Login Screen Name' => ActsAsTable::Path.new(Post).belongs_to(:blog).belongs_to(:user).attribute(:login),
    },
  },
}
```

To achieve the goal, first, seed the database with a new ActsAsTable row model.

* `db/seeds.rb`

```ruby
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }], without_protection: true)
#   Mayor.create(name: 'Emanuel', city: cities.first)

ActsAsTable::RowModel.create(name: 'ActsAsTable row model for post->blog->user') do |row_model|
  row_model.draw do
    # @return [ActsAsTable::Path<Post>]
    post_path = ActsAsTable::Path.new(Post)

    # @return [ActsAsTable::Path<Blog>]
    post_blog_path = post_path.belongs_to(:blog)

    # @return [ActsAsTable::Path<User>]
    post_blog_user_path = post_blog_path.belongs_to(:user)

    self.columns = {
      'Protected' => {
        'User' => {
          'Login Screen Name' => post_blog_user_path.attribute(:login),
          'Email Address' => post_blog_user_path.attribute(:email),
        },
      },
      'Public' => {
        'Blog' => {
          'Title' => post_blog_path.attribute(:title),
        },
        'Post' => {
          'Title' => post_path.attribute(:title),
          'Abstract' => post_path.attribute(:abstract),
          'Date Created' => post_path.attribute(:created_at),
          'Date Modified' => post_path.attribute(:updated_at),
        },
      },
    }

    # @return [ActsAsTable::Mapper::RecordModel<User>]
    post_blog_user_model = model 'User' do
      attribute :login, post_blog_user_path.attribute(:login)
      attribute :email, post_blog_user_path.attribute(:email)
    end

    # @return [ActsAsTable::Mapper::RecordModel<Blog>]
    post_blog_model = model 'Blog' do
      attribute :title, post_blog_path.attribute(:title)

      belongs_to :user, post_blog_user_model
    end

    # @return [ActsAsTable::Mapper::RecordModel<Post>]
    post_model = model 'Post' do
      attribute :title, post_path.attribute(:title)
      attribute :abstract, post_path.attribute(:abstract)
      attribute :created_at, post_path.attribute(:created_at)
      attribute :updated_at, post_path.attribute(:updated_at)

      belongs_to :blog, post_blog_model
    end    

    self.root_model = post_model
  end
end
```

Finally, serialize the data using the [ActsAsTable::CSV](https://github.com/pnnl/acts_as_table_csv) extension:
```ruby
# @return [ActsAsTable::RowModel]
row_model = ActsAsTable::RowModel.find(1)

# @return [ActiveRecord::Relation<Post>]
posts = Post.all

ActsAsTable.for(:csv).writer(row_model, $stdout) do |writer|
  posts.each do |post|
    writer << post
  end
end
```

See documentation for [ActsAsTable::CSV](https://github.com/pnnl/acts_as_table_csv) extension for more parsing/serializing examples.

## Author

* [Mark Borkum](https://github.com/markborkum)

## License

This software is licensed under a 3-clause BSD license.

For more information, see the accompanying {file:LICENSE} file.
