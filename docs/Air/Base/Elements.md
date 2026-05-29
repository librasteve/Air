Air::Base::Elements
-------------------

The set of layout and functional web components that Air provides for use in web pages.

The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico [docs](https://picocss.com/docs). Did we say that Air::Base implements Pico CSS?

Layout Elements
---------------

### role Content does Component is export {}

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

### role LeftMenu does Component is export

### has Str $.hx-swap

HTMX swap strategy

### has Positional[<anon>] @.items

list of name => Content Pairs

### method make-routes

```raku
method make-routes() returns Mu
```

makes routes for each content item must be called from within a Cro route block

### role Dashboard does Component is export

### role Panel does Component is export

### has Int $.order

specify sequential order of panel

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

Content Elements
----------------

### role Markdown does Component is export

### has Str $.markdown

markdown to be converted

### has Air::Functional::Markup(Any) $!result

cache the result

### method new

```raku
method new(
    Str $markdown,
    *%h
) returns Mu
```

.new positional takes Str $code

### role Background does Component



background location steps: - set box width and height to actual image dimensions in px (this box is rotated) - X dimension - place left of box in center of page left<50%> - then translate leftwards by half the box width translate(-50%,xx) - Y dimension - set top of box to a fixed point a bit more than half the height for heading - then translate upwards by half the box width translate(xx,-50%) - typical result - transform: translate(-50%, -50%) rotate(-90deg);

### has Mu $.src

src url of background image

### has Mu $.top

top of background image ('140px')

### has Mu $.left

left of background image ('0vw')

### has Mu $.width

width of background image ('100vw')

### has Mu $.height

height of background image ('320px')

### has Mu $.size

size of background image ('auto') <auto cover>

### has Mu $.opacity

opacity of background image (0.1)

### has Mu $.filter

filter - ('grayscale(100%)')

### has Mu $.translate

transform - translate XY

### has Mu $.rotate

transform - rotate (0) (in deg)

### role Logos does Component is export

package Elements::EXPORT::DEFAULT
---------------------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

