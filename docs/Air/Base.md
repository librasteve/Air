

The Tagged Role provides an HTML method so that the consuming class behaves like a standard HTML tag that can be provided with inner and attr attributes

### method HTML

```raku
method HTML() returns Mu
```

Shun html escape even though inner is Str No opener, closer required

### has Str $.theme-color

<amber azure blue cyan fuchsia green indigo jade lime orange pink pumpkin purple red violet yellow> (pico theme)

### has Str $.bold-color

one from <aqua black blue fuchsia gray green lime maroon navy olive purple red silver teal white yellow> (basic css)

### method style

```raku
method style() returns Mu
```

example of optional grid style from https://cssgrid-generator.netlify.app/

package EXPORT::DEFAULT
-----------------------

put in all the @components as functions viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

