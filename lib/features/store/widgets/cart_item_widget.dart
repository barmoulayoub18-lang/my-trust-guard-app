import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItemWidget extends StatefulWidget {
  final Map item;
  final VoidCallback onChanged;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;

  Future<void> increaseQty() async {
    setState(() => isLoading = true);

    final qty = (widget.item['quantity'] ?? 1) + 1;

    await supabase
        .from('cart_items')
        .update({"quantity": qty})
        .eq('id', widget.item['id']);

    widget.onChanged();

    setState(() => isLoading = false);
  }

  Future<void> decreaseQty() async {
    setState(() => isLoading = true);

    final current = widget.item['quantity'] ?? 1;

    if (current <= 1) {
      await supabase
          .from('cart_items')
          .delete()
          .eq('id', widget.item['id']);
    } else {
      await supabase
          .from('cart_items')
          .update({"quantity": current - 1})
          .eq('id', widget.item['id']);
    }

    widget.onChanged();

    setState(() => isLoading = false);
  }

  Future<void> removeItem() async {
    setState(() => isLoading = true);

    await supabase
        .from('cart_items')
        .delete()
        .eq('id', widget.item['id']);

    widget.onChanged();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.item['products'];
    final name = product['name'] ?? '';
    final price = product['price'] ?? 0;
    final image = product['image_url'];
    final qty = widget.item['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image == null
                ? Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  )
                : Image.network(
                    image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$price",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: isLoading ? null : decreaseQty,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      "$qty",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : increaseQty,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : removeItem,
            icon: const Icon(Icons.delete, color: Colors.red),
          )
        ],
      ),
    );
  }
}