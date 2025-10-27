Air::Base::Tags
---------------

Air::Functional converts all HTML tags into raku functions. Air::Base overrides a subset of these HTML tags, providing them both as `roles` and functions.

Air::Base::Tags often embed some code to provide behaviours. This can be simple - `role Script {}` just marks JavaScript as exempt from HTML Escape. Or complex - `role Body {}` has `Header`, `Main` and `Footer` attributes with certain defaults and constructors.

Combine these tags in the same way as the overall layout of an HTML webpage. Note that they hide complexity to expose only relevant information to the fore. Override them with your own roles and classes to implement your specific needs.

Utility Tags
------------

These HTML Tags are re-published for Air::Base since we need to have roles declared for types anyway. Some have a few minor "improvements" via the setting of attribute defaults.

### role Script does Tag[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

no html escape

### role Style does Tag[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

no html escape

### role Meta does Tag[Singular] {}

### role Title does Tag[Regular] {}

### role Link does Tag[Regular] {}

### role A does Tag[Regular] {}

Semantic Tags
-------------

These are a mix of HTML Tags re-published (some with minor improvements) and of newly construed Air Tags for convenience. Generally they are chosen to align with the Pico CSS semantic tags in use.

### role Button does Tag[Regular] {}

### role Section does Tag[Regular] {}

### role Article does Tag[Regular] {}

### role Aside does Tag[Regular] {}

### role Time does Tag[Regular] {...}

In HTML the time tag is typically of the form < time datetime="2025-03-13" > 13 March, 2025 < /time > . In Air you can just go time(:datetime < 2025-02-27 > ); and raku will auto format and fill out the inner human readable text.

Optionally specify mode => [time | datetime], mode => date is default

### role Content does Tag[Regular] {}

### role Spacer does Tag[Regular] {}

Safe Tag
--------

The Air way to suppress HTML::Escape

### role Safe does Tag[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

avoids HTML escape

package Tags::EXPORT::DEFAULT
-----------------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

