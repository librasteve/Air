Air::Base::Elements
-------------------

The set of layout and functional web components that Air provides for use in web pages.

The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico [docs](https://picocss.com/docs). Did we say that Air::Base implements Pico CSS?

Layout Elements
---------------

### role Table does Component is export

Attrs thead, tbody and tfoot can each be a 1D [values] or 2D Array [[values],] that iterates to row and columns or a Tag|Component - if the latter then they are just rendered via their .HTML method. This allow for single- and multi-row thead and tfoot.

Table applies col and row header tags <th></th> as required for Pico styles.

### has Mu $.tbody

optional (ie tbody-attrs only is ok)

### has Associative %.tbody-attrs

explicitly specify attrs on tbody

### has Mu $.thead

optional

### has Mu $.tfoot

optional

### has Mu $.class

class for table

### method new

```raku
method new(
    *@tbody,
    *%h
) returns Mu
```

.new positional takes tbody unless passed as attr

### role Grid does Component is export

### has Positional @.items

list of items to populate grid

### method new

```raku
method new(
    *@items,
    *%h
) returns Mu
```

.new positional takes @items

### role Flexbox does Component is export

### has Positional @.items

list of items to populate grid,

### has Mu $.direction

flex-direction (default row)

### has Mu $.gap

gap between items in em (default 1)

### method new

```raku
method new(
    *@items,
    *%h
) returns Mu
```

.new positional takes @items

### role Dashboard does Component is export

### role Box does Component is export

### has Int $.order

specify sequential order of box

### role Tab does Tag[Regular] {...}

### subset TabItem of Pair where .value ~~ Tab;

### role Tabs does Component is export



Tabs does Component is export to control multiple tabs

### has Str $.align-menu

Tabs take two attrs for menu alignment The default is to align="left" and to not adapt to media width $.align-menu <left right center> sets the overall preference

### has Str $.adapt-menu

$.adapt-menu <'' left right center> sets the value for small viewport

### has Positional[Elements::TabItem] @.items

list of tab sections

### method new

```raku
method new(
    *@items,
    *%h
) returns Mu
```

.new positional takes @items

### method make-routes

```raku
method make-routes() returns Mu
```

makes routes for Tabs must be called from within a Cro route block

Action Elements
---------------

### role Dialog does Component is export

### role Lightbox does Component is export

### has Str $.label

unique lightbox label

### has Associative %.attrs

can be provided with attrs

### has Positional @.inners

can be provided with inners

### method new

```raku
method new(
    *@inners,
    *%attrs
) returns Mu
```

ok to call .new with @inners as Positional

Other Elements
--------------

### role Markdown does Component is export

### has Str $.markdown

markdown to be converted

### method new

```raku
method new(
    Str $markdown,
    *%h
) returns Mu
```

.new positional takes Str $code

### role Background does Component

### has Mu $.top

top of background image (in px)

### has Mu $.height

height of background image (in px)

### has Mu $.url

url of background image

### has Mu $.opacity

opacity of background image

### has Mu $.rotate

rotate angle of background image (in deg)

package Elements::EXPORT::DEFAULT
---------------------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

