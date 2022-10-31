<?php

namespace App\Tests;

use App\Entity\Product;
use App\Repository\ProductRepository;
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class ProductTest extends WebTestCase
{
    public const PRODUCT = 'Produit';

    public function testCreateProduct(): void
    {
        $productName = self::PRODUCT.uniqid();

        $client = static::createClient();
        self::bootKernel();
        $client->request('GET', '/product/new');

        $client->submitForm('Save', [
            'product[name]' => $productName,
            'product[quantity]' => 1,
            'product[reference]' => 'DELETE 3',
        ]);

        $container = self::getContainer();
        $productRepo = $container->get(ProductRepository::class)->count(['name' => $productName]);

        if (!$productRepo) {
            $this->fail('Product don\'t create');
        }

        $this->assertResponseRedirects();
    }

    public function testDetailProduct(): void
    {
        $client = static::createClient();
        self::bootKernel();

        $productName = self::PRODUCT.uniqid();

        $product = (new Product())->setName($productName)
            ->setQuantity(4)
            ->setReference('DetailP')
            ->setCreatedAt(new \DateTimeImmutable())
            ->setUpdatedAt(new \DateTimeImmutable());

        $container = static::getContainer();

        $productRepository = $container->get(ProductRepository::class);
        $productRepository->save($product, true);

        $client->request('GET', '/product/'.$product->getId());

        $this->assertResponseStatusCodeSame(200);
    }

    public function testProductList(): void
    {
        $client = static::createClient();
        $client->request('GET', '/product/');

        $this->assertResponseStatusCodeSame(200);
    }

    public function testEditProduct(): void
    {
        $client = static::createClient();
        self::bootKernel();

        $product = (new Product())->setName('Detail Product Edit')
            ->setQuantity(4)
            ->setReference('DetailP Edit')
            ->setCreatedAt(new \DateTimeImmutable())
            ->setUpdatedAt(new \DateTimeImmutable());

        $container = static::getContainer();

        $productRepository = $container->get(ProductRepository::class);
        $productRepository->save($product, true);

        $productName = self::PRODUCT.uniqid();

        $client->request('GET', '/product/'.$product->getId().'/edit');

        $client->submitForm('Save', [
            'product[name]' => $productName,
            'product[quantity]' => 5,
            'product[reference]' => 'Edition',
        ]);

        if (!$container->get(ProductRepository::class)->count(['name' => $productName])) {
            $this->fail('Le produit n\'existe pas');
        }

        $this->assertResponseRedirects();
    }

    public function testDeleteProduct(): void
    {
        $client = static::createClient();
        self::bootKernel();

        $product = (new Product())->setName('Delete')
            ->setQuantity(4)
            ->setReference('DetailP Edit')
            ->setCreatedAt(new \DateTimeImmutable())
            ->setUpdatedAt(new \DateTimeImmutable());

        $container = static::getContainer();

        $productRepository = $container->get(ProductRepository::class);
        $productRepository->save($product, true);

        $client->request('POST', '/product/'.$product->getId());

        $this->assertResponseRedirects();
    }
}
