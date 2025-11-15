Air::Base::Widgets
------------------

Active tags that can be used anywhere to provide a nugget of UI behaviour, default should be a short word (or a single item) that can be used in Nav

### role LightDark does Tag[Regular] does Widget {...}

### method HTML

```raku
method HTML() returns Mu
```

attribute 'show' may be set to 'icon'(default) or 'buttons'

package Widgets::EXPORT::DEFAULT
--------------------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

