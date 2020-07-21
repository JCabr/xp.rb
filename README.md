[![Gem](https://img.shields.io/gem/v/xprint.svg?color=blue&style=for-the-badge&logo=ruby)](https://rubygems.org/gems/xprint)

# xprint.rb

Gem that allows for pretty printing data over multiple lines and
with indentation, but unlike the common methods for printing will
also work for any object.

xprint will:
- Show basic kinds of data (numbers, strings, symbols, booleans, nil) 
  pretty much as-is.
    - Also supports commonly used data objects like:
        - Proc, Date, Time, DateTime, BigDecimal, and Rational.
- Show structured data (Arrays/Hashes/Objects) over multiple lines with 
  everything indented consistently.
  - Arrays show a list of all items, also showing the index for each item.
  - Hashes show all `key => value` pairs, with all `=>`'s aligned to allow
    for consistently being able to see where the value starts.
  - Objects show all attributes in the format `@var = value`, where
    all the `=`'s are aligned like with Hashes.
    - Structs are also covered, being slightly different but
      are shown the same way.
    - Modules are also covered.
- Any nested data, like an object inside of an object, will be shown fully.


The name is short for "X-panding Print".

## Sections
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)

&nbsp;

## Installation

### With Gem
#### Windows
```sh
gem install xprint --platform=ruby
 ```

### Linux / macOS
```sh
gem install xprint
```

### With Bundler
With Bundler, you can add xprint to your Gemfile:
```sh
gem xprint
```
And then install via `bundle install`

&nbsp;

## Usage
xprint is very easy to use, as all you have to do is use the `xp` function:
```rb
require 'xprint'

data = {
    people: [
        {
            name: 'Jim',
            age: 19,
            hobbies: ['Video Games']
        },
        {
            name: 'Jam',
            age: 34,
            hobbies: ['Eating Jam']
        }
    ]
}

xp data
```
Output:
```rb
{
  :people => [
    {
      :name    => "Jim", 
      :age     => 19, 
      :hobbies => [
        [0] "Video Games"
      ]
    }, 
    {
      :name    => "Jam", 
      :age     => 34, 
      :hobbies => [
        [0] "Eating Jam"
      ]
    }
  ]
}
```

&nbsp;

Unlike some pretty printing libraries, xprint automatically works with
arbitrary objects to see their instance variables:
```rb
class Person
    attr_accessor :name, :age, :hobbies

    def initialize(name, age, *hobbies)
        @name    = name
        @age     = age
        @hobbies = hobbies
    end
end

jim = Person.new 'Jim', 19, 'Video Games'
jam = Person.new 'Jam', 34, 'Eating Jam'

data = { people: [jim, jam] }

xp data
```
Output:
```rb
{
  :people => [
    Person(
      @name    = "Jim"
      @age     = 19
      @hobbies = [
        [0] "Video Games"
      ]
    ), 
    Person(
      @name    = "Jam"
      @age     = 34
      @hobbies = [
        [0] "Eating Jam"
      ]
    )
  ]
}
```

It also works with Structs, which are slightly different than standard
objects:
```rb
Person = Struct.new(:name, :age, :hobby)
xp Person.new 'Jim', 19, 'Video Games'
```
Output:
```rb
Struct Person(
  name  = "Jim"
  age   = 19
  hobby = "Video Games"
)
```
&nbsp;

If you want to get the text for some data in the same format `xp` uses, you
can use the `xpand` function.

This allows you to use the expanded data text inside other text, like so:

```rb
# We'll be using the same Person class from the previous example.
jim = Person.new 'Jim', 19, 'Video Games'
jam = Person.new 'Jam', 34, 'Eating Jam'

data = [jim, jam]
puts "people: #{xpand data}"
```
Ouput:
```rb
people: [
  Person(
    @name    = "Jim"
    @age     = 19
    @hobbies = [
      [0] "Video Games"
    ]
  ), 
  Person(
    @name    = "Jam"
    @age     = 34
    @hobbies = [
      [0] "Eating Jam"
    ]
  )
]
```
&nbsp;

Note that if you don't want to use the functions from the global
namespace, you can call the same function via 
`XPrint::xp` or `XPrint::xpand`.

&nbsp;

## Customization
You can customize some general details about how xprint functions, such as
if it prints out colored text (if you're using a terminal that supports
colors) and the text to use for each "tab" used when indenting data.

To customize these features, you just modify the XPrint module:
```rb
# Want 4 spaces for tabs and no braces? Do this:
XPrint.set tab: ' ' * 4,  braces: false

friends = {
    'Jim' => {
        favorite_numbers: [1, 2, 3]
    },
    'Jam' => {
        favorite_numbers: [2, 6]
    }
}
xp friends
```
Output:
```rb
"Jim" => 
    :favorite_numbers => 
        [0] 1 
        [1] 2 
        [2] 3
"Jam" => 
    :favorite_numbers => 
        [0] 2 
        [1] 6
```

Check out
[this wiki page](https://github.com/JCabr/xprint.rb/wiki/Customization)
for more in-depth details about customizing xprint, such as how to
put your settings into a file and load the settings in your code.