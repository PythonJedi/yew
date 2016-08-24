Algebraic Types are generally the domain of languages like Haskell and OCaml.
However, the core tenants can be applied to less abstract languages such as Java
through a bit of creative thinking and some restriction on what may be allowed.

## Basis of Algebraic Types

Simple algebraic types consist of three 'constructors': Function, Product, and
Sum (or Coproduct). Each of these constructors take two types and return a
different type. Each constructor also has an associated 'map' function that
takes two functions and combines them in a similar way as the types. Let's start
with product, as it is the most straightforward.

### Product

  public class Product<A, B> {
    private A left;
    private B right;

    public static Product(A a, B b) {
      this.left = a;
      this.rght = b;
    }

    public static A projleft(Product<A,B> p) {
      return p.left;
    }

    public static B projright(Product<A,B> p) {
      return p.right;
    }

    public static Function<Product<A,B>,Product<C,D>> map (Function<A,C> f,
                                                           Function<B,D> g) {
      return p -> Product<C,D>(f.call(Product<A,B>.projleft(p)),
                               g.call(Product<A,B>.projright(p)))
    }

    public static Product<A,A> double (A a) {
      return Product<A,A>(a,a);
    }
  }

Product is used to have two values or functions attached to one another so that
they may be passed around as a single entity. Notice that there is no way to
modify the values inside a product. This is a feature known as immutability, and
it makes programs a lot simpler to reason about.

The type signature of Product<A,B>.map includes Function as a type constructor.
This is necessary because java doesn't allow functions as direct types. In order
to pass around functions we must encapsulate them in an object. Let us therefore
take a look at Function.

### Function

  public interface Function<A,B> {
    B call(A a);

    static Function<Function<B,C>,Function<A,D>> map (Function<A,B> f,
                                                      Function<C,D> g) {
      return h -> (a -> g.call(h.call(f.call(a))))
    }

    static  Function<A,C> compose (Function<A,B> f, Function<B,C> g) {
      return a -> g.call(f.call(a))
    }
  }

Function is a bit special because of java's aforementioned issues with
first-class functions. In order to instantiate a Function, one must create a
class that implements Function. Alternately, one can use a lambda expression.
In fact, lambda expressions and composition are the bread and butter of
functional programming, hence why the definition of Function includes a compose
helper along with the more flexible map. With function defined, all we have left
to consider for basic algebraic data types is the Sum or Coproduct.

### Sum

  public class Sum<A,B> {
    private enum Side {Left, Right}
    private A left;
    private B right;
    private Side which;

    public Sum(A a) {
      this.which = Left;
      this.left = a;
    }

    public Sum(B b) {
      this.which = Right;
      this.right = b;
    }

    public static Function<Sum<A,B>,Sum<C,D>> map (Function<A,C> f,
                                                   Function<B,D> g) {
      return s -> Sum<C,D>(s.which == Side.Left ? f.call(s.left) :
                                                  g.call(s.right));
    }

    public static A unwrap(Sum<A,A> a) {
      return a.which == Side.Left ? a.left : a.right;
    }
  }

The most important part of Sum is that any instance of Sum only has one of its
two possible 'spaces' filled. Thus Sum represents the type that could be either
A or B, but not both at the same time. This is in contrast to Product which must
have both spaces filled at construction. Also notice that Sum has two was to
wrap a value as a Sum, while Product has two ways to unwrap a product into a
value. This kind of relationship where two things are related with components
reversed is known in mathematics as duality, and we'll be exploring it for the
entirety of this document.
