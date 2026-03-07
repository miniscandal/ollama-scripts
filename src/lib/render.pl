#!/usr/bin/env perl

use strict;
use warnings;

# Leer toda la entrada de una vez
undef $/;
my $input = <STDIN>;
exit unless $input;

# Dividir el contenido buscando bloques de código con cerramientos ```
# El modificador /ms permite que . coincida con saltos de línea y modo multilínea
my @chunks = split(/(^```.*?^```)/ms, $input);

foreach my $chunk (@chunks) {
    next unless $chunk =~ /\S/; # Saltar fragmentos vacíos

    if ($chunk =~ /^```/) {
        # Es un bloque de código: usamos batcat
        # Tip: Usamos -l md para que bat detecte el lenguaje dentro del bloque markdown
        open(my $pipe, "| batcat --style=header,grid,numbers --theme='Sublime Snazzy' --paging=never -l md") 
            or warn "Error al abrir batcat: $!";
        print $pipe $chunk;
        close($pipe);
    } else {
        # Es texto normal o markdown sin bloques de código: usamos glow
        open(my $pipe, "| glow -") 
            or warn "Error al abrir glow: $!";
        print $pipe $chunk;
        close($pipe);
    }
}




# #!/usr/bin/env perl
# use strict;
# use warnings;

# # Este script segmenta un texto Markdown en bloques de texto y bloques de código,
# # enviando cada parte a la herramienta de renderizado correspondiente.

# # Leer toda la entrada (modo slurp)
# undef $/;
# my $input = <STDIN>;

# # Obtener comandos de las variables de entorno o usar valores por defecto
# my $bat_cmd   = $ENV{BAT_CMD}   || 'batcat';
# my $bat_style = $ENV{BAT_STYLE} || '--style=plain';
# my $glow_cmd  = $ENV{GLOW_CMD}  || 'glow';
# my $glow_style = $ENV{GLOW_STYLE} || '-';

# # Segmentar el texto buscando bloques de código con ```
# # El uso de paréntesis en el split preserva los delimitadores
# foreach my $chunk (split /(^```[\s\S]*?^```)/m, $input) {
#     # Ignorar fragmentos que solo contienen espacios en blanco
#     next unless $chunk =~ /\S/;

#     # Determinar el comando a ejecutar
#     my $cmd = ($chunk =~ /^```/) 
#         ? "$bat_cmd $bat_style" 
#         : "$glow_cmd $glow_style";

#     # Abrir pipe hacia el comando y enviar el fragmento
#     if (open(my $pipe, "|-", $cmd)) {
#         print $pipe $chunk;
#         close($pipe);
#     } else {
#         # Fallback: imprimir texto plano si el comando falla
#         print $chunk;
#     }
# }
