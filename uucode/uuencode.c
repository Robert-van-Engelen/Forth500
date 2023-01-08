/*
 uuencode.c - uuencoder with option to include SHARP PC-E500 binary file header
 with starting address for LOAD M

 -------------------------------------------------------------------------------

 BSD 3-Clause License
 
 Copyright (c) 2021, Robert van Engelen
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 -------------------------------------------------------------------------------
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void usage()
{
  printf("Usage: uuencode [-a address] file\n");
  exit(EXIT_FAILURE);
}

void error(const char *msg, const char *arg)
{
  fprintf(stderr, msg, arg);
  perror(" error");
  exit(EXIT_FAILURE);
}

int main(int argc, char **argv)
{
  int           header = 0;
  unsigned long address;
  const char   *infile;
  size_t        len;
  const char   *ext;
  char         *outfile;
  FILE         *ifd;
  FILE         *ofd;
  char          buf[45];
  size_t        i;
  unsigned      byte;

  if (argc < 2)
    usage();

  if (strncmp(argv[1], "-a", 2) == 0) {
    if (argc < 3)
      usage();
    header = 1;
    if (argv[1][2] != '\0') {
      address = strtoul(&argv[1][2], NULL, 0);
      infile = argv[2];
    }
    else {
      if (argc < 4)
	usage();
      address = strtoul(argv[2], NULL, 0);
      infile = argv[3];
    }
    if (address > 0xffff && address < 0xb0000)
      usage();
  }
  else {
    infile = argv[1];
  }

  len = strlen(infile);
  if (len == 0)
    usage();

  outfile = malloc(len + 5);
  strcpy(outfile, infile);

  ext = strrchr(infile, '.');
  if (ext == NULL)
    strcat(outfile, isupper(infile[0]) ? ".UUE" : ".uue");
  else
    strcpy(outfile + (ext - infile), isupper(infile[0]) && isupper(ext[1]) ? ".UUE" : ".uue");

  ifd = fopen(infile, "r");
  if (ifd == NULL)
    error("Cannot open %s for reading", infile);

  ofd = fopen(outfile, "w");
  if (ofd == NULL)
    error("Cannot open %s for writing", outfile);

  printf("UUENCODE %s -> %s", infile, outfile);
  if (header)
    printf(" PC-E500 start address 0x%lx\n", address);
  else
    printf("\n");

  fprintf(ofd, "begin 644 %s\r\n", infile);

  do {
    memset(buf, 0, 45);

    if (header) {
      memcpy(buf, "\xff\x00\x06\x01\x10\x00\x00\x00\x00\x00\x0b\xff\xff\xff\x00\x0f", 16);
      buf[5] = address & 0xff;
      buf[6] = address >> 8;
      len = 16 + fread(buf + 16, 1, 45 - 16, ifd);
      header = 0;
    }
    else {
      len = fread(buf, 1, 45, ifd);
    }

    if (len > 0) {
      fputc(len + 32, ofd);
      for (i = 0; i < len; i += 3) {
	byte = (buf[i] & 0xfc) >> 2;
	fputc(byte + (byte ? 32 : 96), ofd);
	byte = ((buf[i] & 0x03) << 4) | (buf[i+1] & 0xf0) >> 4;
	fputc(byte + (byte ? 32 : 96), ofd);
	byte = ((buf[i + 1] & 0x0f) << 2) | (buf[i+2] & 0xc0) >> 6;
	fputc(byte + (byte ? 32 : 96), ofd);
	byte = buf[i + 2] & 0x3f;
	fputc(byte + (byte ? 32 : 96), ofd);
      }
      fprintf(ofd, "\r\n");
    }
  }
  while (len == 45);

  fprintf(ofd, "`\r\nend\r\n\x1a");

  fclose(ofd);
  fclose(ifd);

  free(outfile);
}
