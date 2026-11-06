/* bars.c - cycle the border colour once per frame. */

/* 16-bit I/O ports: __banked makes SDCC load the whole address into BC. */
__sfr __banked __at(0x7f00) gate_array;   /* Gate Array */
__sfr __banked __at(0xf500) ppi_port_b;   /* PPI port B, bit 0 = vertical sync */

static void set_border(unsigned char hw_colour)
{
    gate_array = 0x10;                    /* select the border */
    gate_array = 0x40 | hw_colour;        /* hardware colour 0-31 */
}

static void wait_frame(void)
{
    while (ppi_port_b & 1)
        ;
    while (!(ppi_port_b & 1))
        ;
}

void main(void)
{
    unsigned char colour = 0;

    for (;;) {
        wait_frame();
        set_border(colour++ & 31);
    }
}
