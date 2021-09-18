#define stack_push(this, ...)    (this = [__VA_ARGS__] + this)
#define stack_push_list(this, lst)  (this = lst + this)
#define stack_peek(type, this)    llList2##type(this, 0)
#define stack_peekn(type, this, n)    llList2##type(this, n)
#define stack_drop(this)    (this = llDeleteSubList(this, 0, 0))
#define stack_dropn(this, n)    (this = llDeleteSubList(this, 0, (n) - 1))
#define stack_pop(type, this)    stack_peek(type, this); stack_drop(this)