- Base/
    - Tags.rakumod
        - role Script      does Tag[Regular]
        - role Style       does Tag[Regular]
        - role Meta        does Tag[Singular]
        - role Title       does Tag[Regular]
        - role Link        does Tag[Singular]
        - role External    does Tag[Regular]
        - role Internal    does Tag[Regular]
        - role A           does Tag[Regular]
        - role Button      does Tag[Regular]
        - role Content     does Tag[Regular]
        - role Section     does Tag[Regular]
        - role Article     does Tag[Regular]
        - role Aside       does Tag[Regular]
        - role Time        does Tag[Regular]
        - role Spacer      does Tag[Regular]
        - role Safe        does Tag[Regular]
    - Elements.rakumod
        - use Base::Tags
        - role Table       does Component
        - role Grid        does Component
        - role Flexbox     does Component
        - role Dashboard   does Component
        - role Box         does Component
        - role Tab         does Component
        - role Tabs        does Component
        - role Dialog      does Component
        - role Lightbox    does Component
        - role Markdown    does Component
        - role Background  does Component
    - Tools.rakumod
        - role Tool
        - role Analytics   does Tool
    - Widgets.rakumod
        - role Widget      does Tag[Regular]
        - role LightDark   does Widget
- Base.rakumod
    - use Base::Tags
    - use Base::Elements;
    - use Base::Tools
    - use Base::Widgets
    - role Head        does Tag[Regular]
    - role Header      does Tag[Regular]
    - role Main        does Tag[Regular]
    - role Footer      does Tag[Regular]
    - role Body        does Tag[Regular]
    - role Html        does Tag[Regular]
    - class Nav        does Component
    - class Page       does Component
    - class Site
    - role Defaults

Snagging

- lizmat code for Tags.rakumod etc.

```
for @exports-air-base-tags -> $class {
    my $name := $class.^shortname;
    OUR::{'&' ~ $name.lc} := my sub (|c) { $class.new(|c);
    OUR::{$name} := $class;
}
```

- clean out TEMPINs