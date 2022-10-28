<?php

namespace App\Tests;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class ProductTest extends WebTestCase
{
    public function testCreateProduct(): void
    {
        $client = static::createClient();
        $client->request('GET', '/product/new');

        $client->submitForm('product_save', [
            'product[name]' => 'Produit Test Unitaire 3',
            'product[quantity]' => 1,
            'product[reference]' => 'ATEST 3',
        ]);

        $this->assertResponseRedirects();
    }

    public function testProductNotCreate(): void
    {
        $client = static::createClient();
        $client->request('GET', '/product/new');

        $client->submitForm('product_save', [
            'product[name]' => 'Produit Test Unitaire 3',
            'product[quantity]' => 'sssss',
            'product[reference]' => 'ATEST 3',
        ]);

        $this->assertResponseStatusCodeSame(422);
    }
}
