Air::Base::Tools
----------------

Tools are provided to the `site()` function to provide a nugget of side-wide behaviour, services method defaults are distributed to all pages on server start.

### role Analytics does Tool {...}

### has Provider $.provider

may be [Umami] - others TBD

### has Str $.key

website ID from provider

package Tools::EXPORT::DEFAULT
------------------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

