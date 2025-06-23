import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../models/product.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  List<Map<String, dynamic>> _cartItems = [];
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
        Position position = await Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).first;

        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi diperlukan')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
    }

    setState(() {
      _loadingLocation = false;
    });
  }

  void _addToCart(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Harga: Rp ${product.price.toStringAsFixed(0)}'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Gunakan setState dari _OrderPageState agar UI utama diperbarui
                    this.setState(() {
                      // Cek apakah produk sudah ada di keranjang
                      int existingIndex = _cartItems.indexWhere(
                        (item) => item['product'].id == product.id,
                      );

                      if (existingIndex != -1) {
                        // Jika sudah ada, tambahkan quantity-nya
                        _cartItems[existingIndex]['quantity'] += quantity;
                      } else {
                        // Jika belum ada, tambahkan item baru
                        _cartItems.add({
                          'product': product,
                          'quantity': quantity,
                        });
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get _totalAmount {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item['product'].price * item['quantity']),
    );
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate() && _cartItems.isNotEmpty) {
      bool success = await Provider.of<OrderProvider>(context, listen: false)
          .submitOrder(
            name: _nameController.text,
            phone: _phoneController.text,
            latitude: double.parse(_latController.text),
            longitude: double.parse(_lngController.text),
            cartItems: _cartItems,
            totalAmount: _totalAmount,
          );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dikirim!')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesanan')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data Pelanggan
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Nama harus diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Nomor telepon harus diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex:
                                2,
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                              style: const TextStyle(
                                fontSize: 14,
                              ), // Kecilkan font
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Lokasi harus diisi'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex:
                                3, 
                            child: TextFormField(
                              controller: _lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              enabled: false,
                              style: const TextStyle(
                                fontSize: 14,
                              ), 
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _loadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.location_on),
                          label: Text(
                            _loadingLocation
                                ? 'Mencari Lokasi...'
                                : 'Dapatkan Lokasi',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Produk
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          if (productProvider.products.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.0,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              Product product = productProvider.products[index];
                              return Card(
                                elevation: 2,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _addToCart(product),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'Rp ${product.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Colors.brown[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Keranjang
              if (_cartItems.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keranjang',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            var item = _cartItems[index];
                            Product product = item['product'];
                            int quantity = item['quantity'];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(product.name),
                              subtitle: Text(
                                '$quantity x Rp ${product.price.toStringAsFixed(0)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _cartItems.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${_totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cartItems.isEmpty ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Pesanan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }
}
