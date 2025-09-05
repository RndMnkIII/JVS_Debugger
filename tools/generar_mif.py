#!/usr/bin/env python3
# generar_mif.py
#
# Genera un archivo .mif para inicializar RAM en Quartus
# con el contenido de una cadena ASCII terminada en '\0'

def generar_mif(cadena: str, nombre_archivo: str = "output.mif"):
    # Añadimos el terminador nulo
    data = cadena.encode("ascii") + b"\0"
    depth = len(data)
    width = 8  # RAM de 8 bits por carácter

    with open(nombre_archivo, "w") as f:
        f.write(f"-- Archivo MIF generado automáticamente\n")
        f.write(f"-- Contenido: \"{cadena}\"\n\n")
        f.write(f"WIDTH={width};\n")
        f.write(f"DEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")

        for addr, byte in enumerate(data):
            f.write(f"  {addr:02X} : {byte:02X}; -- {chr(byte) if byte != 0 else '\\0'}\n")

        f.write("END;\n")

    print(f"[OK] Generado {nombre_archivo} con {depth} bytes.")

if __name__ == "__main__":
    cadena = "namco ltd.;NAJV2;Ver1.00;JPN,Multipurpose."
    generar_mif(cadena, "namco.mif")
