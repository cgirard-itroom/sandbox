<?php

namespace App\DataFixtures;

use App\Entity\Product;
use Bezhanov\Faker\Provider\Device;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Faker\Factory;

class ProductFixtures extends Fixture
{
    public const PRODUCT_NUMBER = 800;

    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create();
        $faker->addProvider(new Device($faker));

        for ($i = 0; $i < self::PRODUCT_NUMBER; $i++) {
            $product = (new Product())
                ->setName($faker->deviceModelName)
                ->setCreatedAt(\DateTimeImmutable::createFromFormat('d/m/y', $faker->date('d/m/y')))
                ->setReference($faker->deviceSerialNumber)
                ->setQuantity($faker->numberBetween(0, 600));
            $manager->persist($product);
        }
        // $product = new Product();
        // $manager->persist($product);

        $manager->flush();
    }
}
