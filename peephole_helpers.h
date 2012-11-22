CODE *copy(CODE *original) {
  CODE *c;
  c = NEW(CODE);
  c->kind = original->kind;
  c->visited = 0;
  c->next = NULL;
  return c;
}
