#!/usr/bin/env python3
# generar_mem.py
#
# Genera archivo .mem (hex por línea) a partir de una cadena terminada en '\0'

def generar_mem(cadena: str, nombre_archivo: str = "output.mem"):
    data = cadena.encode("ascii") + b"\0"
    with open(nombre_archivo, "w") as f:
        for byte in data:
            f.write(f"{byte:02X}\n")
    print(f"[OK] Generado {nombre_archivo} con {len(data)} bytes.")

if __name__ == "__main__":
    cadena = "namco ltd.;NAJV2;Ver1.00;JPN,Multipurpose."
    generar_mem(cadena, "namco.mem")
