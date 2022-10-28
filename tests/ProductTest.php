<?php

namespace App\Tests;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class ProductTest extends WebTestCase
{
    public function testSomething(): void
    {
        $client = static::createClient();
        $client->request('GET', '/product/new');

        $client->submitForm('Save', [
            'product[name]' => 'Produit Test Unitaire 3',
            'product[quantity]' => 1,
            'product[reference]' => 'ATEST 3',
        ]);

        $this->assertResponseRedirects();
        $client->followRedirect();
    }
}
